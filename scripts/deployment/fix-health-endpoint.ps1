# Fix Health Endpoint - Add Missing Health Endpoint to API Gateway
Write-Host "🏥 Adding Missing Health Endpoint to API Gateway" -ForegroundColor Cyan

$API_ID = "66a22b8wlb"
$REGION = "us-east-1"

# Get root resource ID
Write-Host "Getting root resource..." -ForegroundColor Gray
$resources = aws apigateway get-resources --rest-api-id $API_ID --output json | ConvertFrom-Json
$rootResourceId = ($resources.items | Where-Object { $_.path -eq "/" }).id
Write-Host "Root resource ID: $rootResourceId" -ForegroundColor Gray

# Create /health resource
Write-Host "Creating /health resource..." -ForegroundColor Yellow
try {
    $healthResource = aws apigateway create-resource --rest-api-id $API_ID --parent-id $rootResourceId --path-part "health" --output json | ConvertFrom-Json
    $healthResourceId = $healthResource.id
    Write-Host "✅ /health resource created: $healthResourceId" -ForegroundColor Green
} catch {
    Write-Host "⚠️  /health resource might already exist, trying to find it..." -ForegroundColor Yellow
    $resources = aws apigateway get-resources --rest-api-id $API_ID --output json | ConvertFrom-Json
    $healthResourceId = ($resources.items | Where-Object { $_.pathPart -eq "health" }).id
    if ($healthResourceId) {
        Write-Host "✅ Found existing /health resource: $healthResourceId" -ForegroundColor Green
    } else {
        Write-Host "❌ Could not create or find /health resource" -ForegroundColor Red
        exit 1
    }
}

# Add GET method for health
Write-Host "Adding GET method to /health..." -ForegroundColor Gray
aws apigateway put-method --rest-api-id $API_ID --resource-id $healthResourceId --http-method GET --authorization-type NONE --no-api-key-required

# Add method response for GET
aws apigateway put-method-response --rest-api-id $API_ID --resource-id $healthResourceId --http-method GET --status-code 200 --response-models "application/json=Empty" --response-parameters "method.response.header.Access-Control-Allow-Origin=false"

# Add MOCK integration for health check
Write-Host "Adding MOCK integration for health check..." -ForegroundColor Gray
aws apigateway put-integration --rest-api-id $API_ID --resource-id $healthResourceId --http-method GET --type MOCK --request-templates "application/json={`"statusCode`": 200}"

# Add integration response with health data
$healthResponse = '{"status": "healthy", "timestamp": "$context.requestTime", "region": "us-east-1", "endpoint": "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod", "cors": "enabled"}'
aws apigateway put-integration-response --rest-api-id $API_ID --resource-id $healthResourceId --http-method GET --status-code 200 --response-templates "application/json=$healthResponse" --response-parameters "method.response.header.Access-Control-Allow-Origin='*'"

# Add OPTIONS method for CORS
Write-Host "Adding CORS support to /health..." -ForegroundColor Gray
aws apigateway put-method --rest-api-id $API_ID --resource-id $healthResourceId --http-method OPTIONS --authorization-type NONE --no-api-key-required

# Add method response for OPTIONS
aws apigateway put-method-response --rest-api-id $API_ID --resource-id $healthResourceId --http-method OPTIONS --status-code 200 --response-parameters "method.response.header.Access-Control-Allow-Headers=false,method.response.header.Access-Control-Allow-Methods=false,method.response.header.Access-Control-Allow-Origin=false"

# Add MOCK integration for OPTIONS
aws apigateway put-integration --rest-api-id $API_ID --resource-id $healthResourceId --http-method OPTIONS --type MOCK --request-templates "application/json={`"statusCode`": 200}"

# Add integration response for OPTIONS
aws apigateway put-integration-response --rest-api-id $API_ID --resource-id $healthResourceId --http-method OPTIONS --status-code 200 --response-parameters "method.response.header.Access-Control-Allow-Headers='Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Requested-With',method.response.header.Access-Control-Allow-Methods='GET,OPTIONS',method.response.header.Access-Control-Allow-Origin='*'"

# Deploy API Gateway
Write-Host "Deploying API Gateway..." -ForegroundColor Yellow
aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod --description "Added health endpoint with CORS"

Write-Host "✅ Health endpoint created and deployed!" -ForegroundColor Green
Write-Host "Test it: https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/health" -ForegroundColor Cyan