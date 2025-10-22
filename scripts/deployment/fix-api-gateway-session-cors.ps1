Write-Host "🔧 Fixing API Gateway CORS for session endpoint..." -ForegroundColor Green

# Get the API Gateway ID
Write-Host "📋 Finding API Gateway..." -ForegroundColor Yellow
$apiId = aws apigateway get-rest-apis --query 'items[0].id' --output text
Write-Host "API ID: $apiId"

# Get the resource ID for /session
Write-Host "📋 Finding session resource..." -ForegroundColor Yellow
$resources = aws apigateway get-resources --rest-api-id $apiId --query 'items[?pathPart==`session`].id' --output text
Write-Host "Session resource ID: $resources"

if ($resources) {
    Write-Host "🔧 Adding OPTIONS method to session resource..." -ForegroundColor Yellow
    
    # Add OPTIONS method
    aws apigateway put-method --rest-api-id $apiId --resource-id $resources --http-method OPTIONS --authorization-type NONE
    
    # Add method response for OPTIONS
    aws apigateway put-method-response --rest-api-id $apiId --resource-id $resources --http-method OPTIONS --status-code 200 --response-parameters "method.response.header.Access-Control-Allow-Headers=false,method.response.header.Access-Control-Allow-Methods=false,method.response.header.Access-Control-Allow-Origin=false"
    
    # Add integration for OPTIONS (mock integration)
    aws apigateway put-integration --rest-api-id $apiId --resource-id $resources --http-method OPTIONS --type MOCK --integration-http-method OPTIONS --request-templates '{"application/json":"{\"statusCode\": 200}"}'
    
    # Add integration response for OPTIONS
    aws apigateway put-integration-response --rest-api-id $apiId --resource-id $resources --http-method OPTIONS --status-code 200 --response-parameters '{"method.response.header.Access-Control-Allow-Headers":"'"'"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"'"'","method.response.header.Access-Control-Allow-Methods":"'"'"'GET,POST,OPTIONS'"'"'","method.response.header.Access-Control-Allow-Origin":"'"'"'*'"'"'"}' --response-templates '{"application/json":""}'
    
    # Deploy the changes
    Write-Host "🚀 Deploying API Gateway changes..." -ForegroundColor Yellow
    aws apigateway create-deployment --rest-api-id $apiId --stage-name prod
    
    Write-Host "✅ CORS configuration updated!" -ForegroundColor Green
    
    # Test the fix
    Write-Host "🧪 Testing OPTIONS request..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5  # Wait for deployment
    
    try {
        $response = Invoke-WebRequest -Uri "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/session" -Method OPTIONS -Headers @{
            'Access-Control-Request-Method' = 'POST'
            'Access-Control-Request-Headers' = 'Content-Type'
            'Origin' = 'http://localhost:3000'
        }
        
        Write-Host "✅ OPTIONS test successful! Status:" $response.StatusCode -ForegroundColor Green
        
    } catch {
        Write-Host "❌ OPTIONS test failed:" $_.Exception.Message -ForegroundColor Red
    }
    
} else {
    Write-Host "❌ Session resource not found!" -ForegroundColor Red
}

Write-Host "🎉 API Gateway CORS fix complete!" -ForegroundColor Green