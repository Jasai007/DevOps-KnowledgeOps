# Copy Exact Working Auth CORS Configuration to Health Endpoint
Write-Host "🏥 Creating Health Endpoint by Copying Working Auth Configuration" -ForegroundColor Cyan

$API_ID = "66a22b8wlb"

# Get root resource
$resources = aws apigateway get-resources --rest-api-id $API_ID --output json | ConvertFrom-Json
$rootResourceId = ($resources.items | Where-Object { $_.path -eq "/" }).id

# Create health resource
Write-Host "Creating /health resource..." -ForegroundColor Yellow
$healthResource = aws apigateway create-resource --rest-api-id $API_ID --parent-id $rootResourceId --path-part "health" --output json | ConvertFrom-Json
$healthResourceId = $healthResource.id
Write-Host "✅ Health resource created: $healthResourceId" -ForegroundColor Green

# Step 1: Add GET method (copy from auth structure)
Write-Host "Adding GET method..." -ForegroundColor Gray
aws apigateway put-method --rest-api-id $API_ID --resource-id $healthResourceId --http-method GET --authorization-type NONE --no-api-key-required

# Add GET method response with CORS header parameter
aws apigateway put-method-response --rest-api-id $API_ID --resource-id $healthResourceId --http-method GET --status-code 200 --response-models 'application/json=Empty' --response-parameters 'method.response.header.Access-Control-Allow-Origin=false'

# Add MOCK integration for GET (exactly like auth)
aws apigateway put-integration --rest-api-id $API_ID --resource-id $healthResourceId --http-method GET --type MOCK --request-templates 'application/json={"statusCode": 200}' --passthrough-behavior WHEN_NO_MATCH --timeout-in-millis 29000

# Add GET integration response with CORS
aws apigateway put-integration-response --rest-api-id $API_ID --resource-id $healthResourceId --http-method GET --status-code 200 --response-templates 'application/json={"status":"healthy","endpoint":"prod"}' --response-parameters 'method.response.header.Access-Control-Allow-Origin=*'

# Step 2: Add OPTIONS method (copy exact auth configuration)
Write-Host "Adding OPTIONS method with exact auth CORS config..." -ForegroundColor Gray
aws apigateway put-method --rest-api-id $API_ID --resource-id $healthResourceId --http-method OPTIONS --authorization-type NONE --no-api-key-required

# Add OPTIONS method response (exactly like auth)
aws apigateway put-method-response --rest-api-id $API_ID --resource-id $healthResourceId --http-method OPTIONS --status-code 200 --response-parameters 'method.response.header.Access-Control-Allow-Headers=false,method.response.header.Access-Control-Allow-Methods=false,method.response.header.Access-Control-Allow-Origin=false'

# Add MOCK integration for OPTIONS (exactly like auth)
aws apigateway put-integration --rest-api-id $API_ID --resource-id $healthResourceId --http-method OPTIONS --type MOCK --request-templates 'application/json={"statusCode": 200}' --passthrough-behavior WHEN_NO_MATCH --timeout-in-millis 29000

# Add OPTIONS integration response (exactly like auth)
aws apigateway put-integration-response --rest-api-id $API_ID --resource-id $healthResourceId --http-method OPTIONS --status-code 200 --response-parameters 'method.response.header.Access-Control-Allow-Headers=Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,method.response.header.Access-Control-Allow-Methods=GET,OPTIONS,method.response.header.Access-Control-Allow-Origin=*'

# Deploy
Write-Host "Deploying API Gateway..." -ForegroundColor Yellow
aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod --description "Health endpoint with copied auth CORS config"

Write-Host "✅ Health endpoint created with working CORS!" -ForegroundColor Green
Write-Host "Test: https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/health" -ForegroundColor Cyan