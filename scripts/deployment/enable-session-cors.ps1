Write-Host "🔧 Enabling CORS for session endpoint..." -ForegroundColor Green

# Get API Gateway info
$apiId = aws apigateway get-rest-apis --query 'items[0].id' --output text
Write-Host "API ID: $apiId"

# Get session resource ID
$sessionResource = aws apigateway get-resources --rest-api-id $apiId --query 'items[?pathPart==`session`].id' --output text
Write-Host "Session resource: $sessionResource"

# Enable CORS for session endpoint
Write-Host "Adding CORS support..." -ForegroundColor Yellow

# Add OPTIONS method
aws apigateway put-method --rest-api-id $apiId --resource-id $sessionResource --http-method OPTIONS --authorization-type NONE

# Add method response
aws apigateway put-method-response --rest-api-id $apiId --resource-id $sessionResource --http-method OPTIONS --status-code 200 --response-parameters "method.response.header.Access-Control-Allow-Headers=false,method.response.header.Access-Control-Allow-Methods=false,method.response.header.Access-Control-Allow-Origin=false"

# Add mock integration
aws apigateway put-integration --rest-api-id $apiId --resource-id $sessionResource --http-method OPTIONS --type MOCK --request-templates '{"application/json":"{\"statusCode\": 200}"}'

# Add integration response
aws apigateway put-integration-response --rest-api-id $apiId --resource-id $sessionResource --http-method OPTIONS --status-code 200 --response-parameters '{"method.response.header.Access-Control-Allow-Headers":"Content-Type,Authorization","method.response.header.Access-Control-Allow-Methods":"GET,POST,OPTIONS","method.response.header.Access-Control-Allow-Origin":"*"}' --response-templates '{"application/json":""}'

# Deploy changes
Write-Host "Deploying changes..." -ForegroundColor Yellow
aws apigateway create-deployment --rest-api-id $apiId --stage-name prod

Write-Host "✅ CORS enabled for session endpoint!" -ForegroundColor Green