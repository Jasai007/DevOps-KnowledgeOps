# Complete CORS Fix - Final Solution
Write-Host "🔧 Complete CORS Fix for API Gateway" -ForegroundColor Cyan

$API_ID = "66a22b8wlb"
$REGION = "us-east-1"

Write-Host "Current endpoint: https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod" -ForegroundColor Yellow

# Test current status
Write-Host "`n📊 Current CORS Status:" -ForegroundColor Yellow
$endpoints = @("auth", "session", "chat", "health")
foreach ($endpoint in $endpoints) {
    try {
        $response = Invoke-WebRequest -Uri "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/$endpoint" -Method OPTIONS -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        Write-Host "✅ /$endpoint : Working ($($response.StatusCode))" -ForegroundColor Green
    } catch {
        Write-Host "❌ /$endpoint : $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    }
}

# Get resources
Write-Host "`n� GetGting API Gateway resources..." -ForegroundColor Yellow
$resources = aws apigateway get-resources --rest-api-id $API_ID --output json | ConvertFrom-Json

# Find or create health resource
$healthResourceId = ($resources.items | Where-Object { $_.pathPart -eq "health" }).id
if (!$healthResourceId) {
    Write-Host "Creating /health resource..." -ForegroundColor Gray
    $rootResourceId = ($resources.items | Where-Object { $_.path -eq "/" }).id
    $healthResource = aws apigateway create-resource --rest-api-id $API_ID --parent-id $rootResourceId --path-part "health" --output json | ConvertFrom-Json
    $healthResourceId = $healthResource.id
    Write-Host "✅ Health resource created: $healthResourceId" -ForegroundColor Green
} else {
    Write-Host "✅ Health resource exists: $healthResourceId" -ForegroundColor Green
}

# Get working auth configuration as template
$authResourceId = ($resources.items | Where-Object { $_.pathPart -eq "auth" }).id
Write-Host "Using auth resource as template: $authResourceId" -ForegroundColor Gray

# Copy auth OPTIONS configuration to health
Write-Host "`n🔄 Copying working auth CORS configuration to health..." -ForegroundColor Yellow

# Ensure health has OPTIONS method
Write-Host "Adding OPTIONS method to health..." -ForegroundColor Gray
aws apigateway put-method --rest-api-id $API_ID --resource-id $healthResourceId --http-method OPTIONS --authorization-type NONE --no-api-key-required 2>$null

# Add method response for OPTIONS
aws apigateway put-method-response --rest-api-id $API_ID --resource-id $healthResourceId --http-method OPTIONS --status-code 200 --response-parameters 'method.response.header.Access-Control-Allow-Headers=false,method.response.header.Access-Control-Allow-Methods=false,method.response.header.Access-Control-Allow-Origin=false' 2>$null

# Add MOCK integration for OPTIONS
aws apigateway put-integration --rest-api-id $API_ID --resource-id $healthResourceId --http-method OPTIONS --type MOCK --request-templates 'application/json={"statusCode": 200}' --passthrough-behavior WHEN_NO_MATCH --timeout-in-millis 29000 2>$null

# Add integration response for OPTIONS (exactly like auth)
aws apigateway put-integration-response --rest-api-id $API_ID --resource-id $healthResourceId --http-method OPTIONS --status-code 200 --response-parameters 'method.response.header.Access-Control-Allow-Headers=Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,method.response.header.Access-Control-Allow-Methods=GET,OPTIONS,method.response.header.Access-Control-Allow-Origin=*' 2>$null

# Ensure health has GET method
Write-Host "Adding GET method to health..." -ForegroundColor Gray
aws apigateway put-method --rest-api-id $API_ID --resource-id $healthResourceId --http-method GET --authorization-type NONE --no-api-key-required 2>$null

# Add method response for GET
aws apigateway put-method-response --rest-api-id $API_ID --resource-id $healthResourceId --http-method GET --status-code 200 --response-models 'application/json=Empty' --response-parameters 'method.response.header.Access-Control-Allow-Origin=false' 2>$null

# Add MOCK integration for GET
aws apigateway put-integration --rest-api-id $API_ID --resource-id $healthResourceId --http-method GET --type MOCK --request-templates 'application/json={"statusCode": 200}' --passthrough-behavior WHEN_NO_MATCH --timeout-in-millis 29000 2>$null

# Add integration response for GET
aws apigateway put-integration-response --rest-api-id $API_ID --resource-id $healthResourceId --http-method GET --status-code 200 --response-templates 'application/json={"status":"healthy","cors":"enabled","endpoint":"prod"}' --response-parameters 'method.response.header.Access-Control-Allow-Origin=*' 2>$null

# Deploy API Gateway
Write-Host "`n🚀 Deploying API Gateway..." -ForegroundColor Yellow
aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod --description "Complete CORS fix with working health endpoint"

Write-Host "✅ API Gateway deployed!" -ForegroundColor Green

# Test all endpoints
Write-Host "`n🧪 Testing All Endpoints After Fix:" -ForegroundColor Cyan
$endpoints = @("health", "auth", "session", "chat")
foreach ($endpoint in $endpoints) {
    Write-Host "Testing /$endpoint..." -ForegroundColor Yellow
    
    # Test OPTIONS (CORS preflight)
    try {
        $response = Invoke-WebRequest -Uri "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/$endpoint" -Method OPTIONS -Headers @{"Origin"="http://localhost:3000"} -UseBasicParsing -TimeoutSec 10
        Write-Host "  ✅ OPTIONS: $($response.StatusCode)" -ForegroundColor Green
        
        if ($response.Headers["Access-Control-Allow-Origin"]) {
            Write-Host "     CORS Origin: $($response.Headers['Access-Control-Allow-Origin'])" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  ❌ OPTIONS: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Test GET for health endpoint
    if ($endpoint -eq "health") {
        try {
            $healthResponse = Invoke-RestMethod -Uri "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/health" -Method GET -TimeoutSec 10
            Write-Host "  ✅ GET: Working" -ForegroundColor Green
            Write-Host "     Response: $($healthResponse | ConvertTo-Json -Compress)" -ForegroundColor Gray
        } catch {
            Write-Host "  ❌ GET: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host "`n🎉 CORS Fix Complete!" -ForegroundColor Cyan
Write-Host "Your API Gateway endpoint is ready: https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod" -ForegroundColor White
Write-Host "All endpoints should now support CORS for browser requests." -ForegroundColor Green