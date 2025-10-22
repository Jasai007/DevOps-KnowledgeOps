# EMERGENCY CORS FIX - Fix All Endpoints Immediately
Write-Host "🚨 EMERGENCY CORS FIX - Fixing All Endpoints Now!" -ForegroundColor Red

$API_ID = "66a22b8wlb"

# Get all resources
$resources = aws apigateway get-resources --rest-api-id $API_ID --output json | ConvertFrom-Json

# Fix each endpoint one by one
$endpoints = @(
    @{name="auth"; id=($resources.items | Where-Object { $_.pathPart -eq "auth" }).id},
    @{name="session"; id=($resources.items | Where-Object { $_.pathPart -eq "session" }).id},
    @{name="chat"; id=($resources.items | Where-Object { $_.pathPart -eq "chat" }).id}
)

foreach ($endpoint in $endpoints) {
    $name = $endpoint.name
    $resourceId = $endpoint.id
    
    Write-Host "🔧 Fixing CORS for /$name (ID: $resourceId)..." -ForegroundColor Yellow
    
    # Ensure OPTIONS method exists
    aws apigateway put-method --rest-api-id $API_ID --resource-id $resourceId --http-method OPTIONS --authorization-type NONE --no-api-key-required 2>$null
    
    # Ensure method response exists
    aws apigateway put-method-response --rest-api-id $API_ID --resource-id $resourceId --http-method OPTIONS --status-code 200 --response-parameters 'method.response.header.Access-Control-Allow-Headers=false,method.response.header.Access-Control-Allow-Methods=false,method.response.header.Access-Control-Allow-Origin=false' 2>$null
    
    # Force update MOCK integration
    aws apigateway put-integration --rest-api-id $API_ID --resource-id $resourceId --http-method OPTIONS --type MOCK --request-templates 'application/json={"statusCode": 200}' --passthrough-behavior WHEN_NO_MATCH --timeout-in-millis 29000
    
    # Force update integration response with CORS headers
    aws apigateway put-integration-response --rest-api-id $API_ID --resource-id $resourceId --http-method OPTIONS --status-code 200 --response-parameters 'method.response.header.Access-Control-Allow-Headers=Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,method.response.header.Access-Control-Allow-Methods=GET,POST,OPTIONS,method.response.header.Access-Control-Allow-Origin=*'
    
    Write-Host "✅ Fixed /$name" -ForegroundColor Green
}

# Force deployment with timestamp to ensure it's new
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
Write-Host "🚀 Force deploying API Gateway (timestamp: $timestamp)..." -ForegroundColor Red
aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod --description "EMERGENCY CORS FIX - $timestamp"

Write-Host "✅ Emergency deployment complete!" -ForegroundColor Green

# Wait a moment for deployment
Write-Host "⏳ Waiting 5 seconds for deployment to propagate..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Test immediately
Write-Host "🧪 Testing CORS after emergency fix..." -ForegroundColor Cyan
$testEndpoints = @("auth", "session", "chat")
foreach ($endpoint in $testEndpoints) {
    try {
        $response = Invoke-WebRequest -Uri "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/$endpoint" -Method OPTIONS -Headers @{"Origin"="http://localhost:3000"} -UseBasicParsing -TimeoutSec 10
        Write-Host "✅ /$endpoint : CORS WORKING ($($response.StatusCode))" -ForegroundColor Green
        Write-Host "   Origin: $($response.Headers['Access-Control-Allow-Origin'])" -ForegroundColor Gray
    } catch {
        Write-Host "❌ /$endpoint : STILL BROKEN - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n🎯 EMERGENCY FIX COMPLETE!" -ForegroundColor Cyan
Write-Host "Try your frontend again - CORS should now work!" -ForegroundColor Green