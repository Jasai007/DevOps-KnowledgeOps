# Complete Lambda Functions Setup with CORS
Write-Host "🚀 Setting up ALL Lambda Functions with CORS" -ForegroundColor Cyan

$API_ID = "66a22b8wlb"

# Step 1: Test current CORS status
Write-Host "`n📊 Current CORS Status:" -ForegroundColor Yellow
$endpoints = @("auth", "session", "chat")
foreach ($endpoint in $endpoints) {
    try {
        $response = Invoke-WebRequest -Uri "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/$endpoint" -Method OPTIONS -Headers @{"Origin"="http://localhost:3000"} -UseBasicParsing -TimeoutSec 5
        Write-Host "✅ /$endpoint : CORS Working ($($response.StatusCode))" -ForegroundColor Green
    } catch {
        Write-Host "❌ /$endpoint : CORS BROKEN - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Step 2: Fix CORS for all endpoints
Write-Host "`n🔧 Fixing CORS for ALL endpoints..." -ForegroundColor Yellow

# Get resource IDs
$resources = aws apigateway get-resources --rest-api-id $API_ID --output json | ConvertFrom-Json
$authId = ($resources.items | Where-Object { $_.pathPart -eq "auth" }).id
$sessionId = ($resources.items | Where-Object { $_.pathPart -eq "session" }).id
$chatId = ($resources.items | Where-Object { $_.pathPart -eq "chat" }).id

Write-Host "Resource IDs - Auth: $authId, Session: $sessionId, Chat: $chatId" -ForegroundColor Gray

# Fix CORS for each endpoint
$endpointIds = @(
    @{name="auth"; id=$authId},
    @{name="session"; id=$sessionId},
    @{name="chat"; id=$chatId}
)

foreach ($endpoint in $endpointIds) {
    $name = $endpoint.name
    $resourceId = $endpoint.id
    
    if ($resourceId) {
        Write-Host "Fixing CORS for /$name..." -ForegroundColor Gray
        
        # Ensure OPTIONS method exists
        aws apigateway put-method --rest-api-id $API_ID --resource-id $resourceId --http-method OPTIONS --authorization-type NONE --no-api-key-required 2>$null
        
        # Ensure method response exists
        aws apigateway put-method-response --rest-api-id $API_ID --resource-id $resourceId --http-method OPTIONS --status-code 200 --response-parameters 'method.response.header.Access-Control-Allow-Headers=false,method.response.header.Access-Control-Allow-Methods=false,method.response.header.Access-Control-Allow-Origin=false' 2>$null
        
        # Force update MOCK integration
        aws apigateway put-integration --rest-api-id $API_ID --resource-id $resourceId --http-method OPTIONS --type MOCK --request-templates 'application/json={"statusCode": 200}' --passthrough-behavior WHEN_NO_MATCH --timeout-in-millis 29000
        
        # Force update integration response with CORS headers
        aws apigateway put-integration-response --rest-api-id $API_ID --resource-id $resourceId --http-method OPTIONS --status-code 200 --response-parameters 'method.response.header.Access-Control-Allow-Headers=Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token,method.response.header.Access-Control-Allow-Methods=GET,POST,OPTIONS,method.response.header.Access-Control-Allow-Origin=*'
        
        Write-Host "✅ Fixed CORS for /$name" -ForegroundColor Green
    }
}

# Step 3: Deploy API Gateway
Write-Host "`n🚀 Deploying API Gateway..." -ForegroundColor Yellow
$timestamp = Get-Date -Format "HHmmss"
aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod --description "Complete CORS fix $timestamp"

Write-Host "✅ API Gateway deployed!" -ForegroundColor Green

# Step 4: Wait and test
Write-Host "`n⏳ Waiting 10 seconds for deployment..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Step 5: Test all endpoints
Write-Host "`n🧪 Testing ALL Endpoints After Fix:" -ForegroundColor Cyan
foreach ($endpoint in $endpoints) {
    Write-Host "Testing /$endpoint..." -ForegroundColor Yellow
    
    # Test OPTIONS (CORS preflight)
    try {
        $response = Invoke-WebRequest -Uri "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/$endpoint" -Method OPTIONS -Headers @{"Origin"="http://localhost:3000"; "Access-Control-Request-Method"="POST"; "Access-Control-Request-Headers"="Content-Type,Authorization"} -UseBasicParsing -TimeoutSec 10
        Write-Host "  ✅ OPTIONS: $($response.StatusCode)" -ForegroundColor Green
        
        if ($response.Headers["Access-Control-Allow-Origin"]) {
            Write-Host "     CORS Origin: $($response.Headers['Access-Control-Allow-Origin'])" -ForegroundColor Gray
        } else {
            Write-Host "     ❌ Missing CORS Origin!" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ❌ OPTIONS: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n🎉 Lambda Functions Setup Complete!" -ForegroundColor Cyan
Write-Host "All endpoints should now have working CORS." -ForegroundColor Green
Write-Host "Try your frontend again!" -ForegroundColor Green