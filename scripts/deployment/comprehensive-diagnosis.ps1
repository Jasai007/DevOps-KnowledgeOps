# Comprehensive CORS and Lambda Diagnosis
Write-Host "🔍 COMPREHENSIVE DIAGNOSIS" -ForegroundColor Red

$API_ID = "66a22b8wlb"
$API_URL = "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod"

Write-Host "`n=== STEP 1: API Gateway Configuration ===" -ForegroundColor Cyan

# Get chat resource
$resources = aws apigateway get-resources --rest-api-id $API_ID --output json | ConvertFrom-Json
$chatResourceId = ($resources.items | Where-Object { $_.pathPart -eq "chat" }).id
Write-Host "Chat Resource ID: $chatResourceId" -ForegroundColor Gray

# Check methods
Write-Host "Available methods:" -ForegroundColor Gray
$chatResource = $resources.items | Where-Object { $_.id -eq $chatResourceId }
if ($chatResource.resourceMethods) {
    $methods = $chatResource.resourceMethods | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
    Write-Host "  Methods: $($methods -join ', ')" -ForegroundColor Gray
}

Write-Host "`n=== STEP 2: Lambda Function Status ===" -ForegroundColor Cyan

# Check Lambda function
try {
    $lambdaConfig = aws lambda get-function-configuration --function-name agentcore-simple-chat --output json | ConvertFrom-Json
    Write-Host "✅ Lambda exists: $($lambdaConfig.FunctionName)" -ForegroundColor Green
    Write-Host "Handler: $($lambdaConfig.Handler)" -ForegroundColor Gray
    Write-Host "Runtime: $($lambdaConfig.Runtime)" -ForegroundColor Gray
    Write-Host "State: $($lambdaConfig.State)" -ForegroundColor Gray
    Write-Host "Last Update Status: $($lambdaConfig.LastUpdateStatus)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Lambda function issue: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== STEP 3: CORS Preflight Test ===" -ForegroundColor Cyan

try {
    $corsResponse = Invoke-WebRequest -Uri "$API_URL/chat" -Method OPTIONS -Headers @{
        "Origin" = "http://localhost:3000"
        "Access-Control-Request-Method" = "POST"
        "Access-Control-Request-Headers" = "Content-Type,Authorization"
    } -UseBasicParsing -TimeoutSec 10
    
    Write-Host "✅ CORS Preflight: $($corsResponse.StatusCode)" -ForegroundColor Green
    
    # Check CORS headers
    $corsHeaders = @("Access-Control-Allow-Origin", "Access-Control-Allow-Methods", "Access-Control-Allow-Headers")
    foreach ($header in $corsHeaders) {
        if ($corsResponse.Headers[$header]) {
            Write-Host "  ✅ $header`: $($corsResponse.Headers[$header])" -ForegroundColor Green
        } else {
            Write-Host "  ❌ Missing: $header" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "❌ CORS Preflight failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== STEP 4: POST Request Test ===" -ForegroundColor Cyan

# Test POST without Authorization
Write-Host "Testing POST without Authorization..." -ForegroundColor Yellow
try {
    $body = '{"message":"test","sessionId":"test"}'
    $response = Invoke-WebRequest -Uri "$API_URL/chat" -Method POST -Body $body -ContentType "application/json" -UseBasicParsing -TimeoutSec 15
    
    Write-Host "✅ POST Success: $($response.StatusCode)" -ForegroundColor Green
    
    # Check response CORS headers
    foreach ($header in $response.Headers.Keys) {
        if ($header -like "*Access-Control*") {
            Write-Host "  Response Header $header`: $($response.Headers[$header])" -ForegroundColor Gray
        }
    }
    
    $responseData = $response.Content | ConvertFrom-Json
    Write-Host "  Response Success: $($responseData.success)" -ForegroundColor Gray
    
} catch {
    Write-Host "❌ POST failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        Write-Host "  Status: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    }
}

# Test POST with Authorization
Write-Host "`nTesting POST with Authorization..." -ForegroundColor Yellow
try {
    $headers = @{
        "Content-Type" = "application/json"
        "Authorization" = "Bearer test-token"
    }
    $body = '{"message":"test with auth","sessionId":"test"}'
    $response = Invoke-WebRequest -Uri "$API_URL/chat" -Method POST -Body $body -Headers $headers -UseBasicParsing -TimeoutSec 15
    
    Write-Host "✅ POST with Auth Success: $($response.StatusCode)" -ForegroundColor Green
    
} catch {
    Write-Host "❌ POST with Auth failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== STEP 5: Lambda Direct Test ===" -ForegroundColor Cyan

# Test Lambda function directly
$testEvent = @{
    httpMethod = "POST"
    headers = @{
        "Content-Type" = "application/json"
    }
    body = '{"message":"direct test","sessionId":"direct"}'
} | ConvertTo-Json -Depth 3

$testEvent | Out-File -FilePath "test-event.json" -Encoding UTF8

try {
    aws lambda invoke --function-name agentcore-simple-chat --payload fileb://test-event.json direct-response.json
    
    if (Test-Path "direct-response.json") {
        $directResponse = Get-Content "direct-response.json" | ConvertFrom-Json
        Write-Host "✅ Lambda Direct Invoke Success" -ForegroundColor Green
        Write-Host "  Status Code: $($directResponse.statusCode)" -ForegroundColor Gray
        
        if ($directResponse.body) {
            $bodyData = $directResponse.body | ConvertFrom-Json
            Write-Host "  Response Success: $($bodyData.success)" -ForegroundColor Gray
        }
        
        Remove-Item "direct-response.json"
    }
    Remove-Item "test-event.json"
} catch {
    Write-Host "❌ Lambda Direct Invoke failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== DIAGNOSIS SUMMARY ===" -ForegroundColor Cyan
Write-Host "Check the results above to identify the exact issue:" -ForegroundColor Yellow
Write-Host "- If CORS Preflight fails: API Gateway CORS issue" -ForegroundColor Gray
Write-Host "- If POST fails but Lambda Direct works: API Gateway integration issue" -ForegroundColor Gray
Write-Host "- If Lambda Direct fails: Lambda function code issue" -ForegroundColor Gray
Write-Host "- If everything works here but frontend fails: Frontend/browser issue" -ForegroundColor Gray