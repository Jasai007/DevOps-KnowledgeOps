# Create Simple Working Health Endpoint
Write-Host "🏥 Creating Simple Working Health Endpoint" -ForegroundColor Cyan

$API_ID = "66a22b8wlb"

# Get root resource
$resources = aws apigateway get-resources --rest-api-id $API_ID --output json | ConvertFrom-Json
$rootResourceId = ($resources.items | Where-Object { $_.path -eq "/" }).id

# Create health resource
Write-Host "Creating /health resource..." -ForegroundColor Yellow
$healthResource = aws apigateway create-resource --rest-api-id $API_ID --parent-id $rootResourceId --path-part "health" --output json | ConvertFrom-Json
$healthResourceId = $healthResource.id
Write-Host "Health resource created: $healthResourceId" -ForegroundColor Green

# Add GET method
Write-Host "Adding GET method..." -ForegroundColor Gray
aws apigateway put-method --rest-api-id $API_ID --resource-id $healthResourceId --http-method GET --authorization-type NONE --no-api-key-required

# Add GET method response with CORS
aws apigateway put-method-response --rest-api-id $API_ID --resource-id $healthResourceId --http-method GET --status-code 200 --response-models 'application/json=Empty' --response-parameters 'method.response.header.Access-Control-Allow-Origin=false'

# Add MOCK integration for GET
aws apigateway put-integration --rest-api-id $API_ID --resource-id $healthResourceId --http-method GET --type MOCK --request-templates 'application/json={"statusCode": 200}'

# Add integration response for GET with CORS
aws apigateway put-integration-response --rest-api-id $API_ID --resource-id $healthResourceId --http-method GET --status-code 200 --response-templates 'application/json={"status":"healthy","cors":"enabled"}' --response-parameters 'method.response.header.Access-Control-Allow-Origin=*'

# Add OPTIONS method for CORS preflight
Write-Host "Adding OPTIONS method for CORS..." -ForegroundColor Gray
aws apigateway put-method --rest-api-id $API_ID --resource-id $healthResourceId --http-method OPTIONS --authorization-type NONE --no-api-key-required

# Add OPTIONS method response
aws apigateway put-method-response --rest-api-id $API_ID --resource-id $healthResourceId --http-method OPTIONS --status-code 200 --response-parameters 'method.response.header.Access-Control-Allow-Origin=false,method.response.header.Access-Control-Allow-Methods=false,method.response.header.Access-Control-Allow-Headers=false'

# Add MOCK integration for OPTIONS
aws apigateway put-integration --rest-api-id $API_ID --resource-id $healthResourceId --http-method OPTIONS --type MOCK --request-templates 'application/json={"statusCode": 200}'

# Add integration response for OPTIONS
aws apigateway put-integration-response --rest-api-id $API_ID --resource-id $healthResourceId --http-method OPTIONS --status-code 200 --response-parameters 'method.response.header.Access-Control-Allow-Origin=*,method.response.header.Access-Control-Allow-Methods=GET,OPTIONS,method.response.header.Access-Control-Allow-Headers=Content-Type'

# Deploy
Write-Host "Deploying API Gateway..." -ForegroundColor Yellow
aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod --description "Simple health endpoint with CORS"

Write-Host "✅ Simple health endpoint created!" -ForegroundColor Green
Write-Host "Test: https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/health" -ForegroundColor Cyan