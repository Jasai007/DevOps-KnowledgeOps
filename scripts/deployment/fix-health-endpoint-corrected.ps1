# Fix Health Endpoint - Corrected Version with Proper JSON
Write-Host "🏥 Fixing Health Endpoint with Proper JSON" -ForegroundColor Cyan

$API_ID = "66a22b8wlb"
$REGION = "us-east-1"

# Get the health resource ID
$resources = aws apigateway get-resources --rest-api-id $API_ID --output json | ConvertFrom-Json
$healthResourceId = ($resources.items | Where-Object { $_.pathPart -eq "health" }).id
Write-Host "Health resource ID: $healthResourceId" -ForegroundColor Gray

if (!$healthResourceId) {
    Write-Host "❌ Health resource not found!" -ForegroundColor Red
    exit 1
}

# Fix GET integration for health
Write-Host "Fixing GET integration for /health..." -ForegroundColor Yellow
aws apigateway put-integration --rest-api-id $API_ID --resource-id $healthResourceId --http-method GET --type MOCK --request-templates 'application/json={"statusCode": 200}'

# Fix integration response with proper JSON
Write-Host "Adding integration response..." -ForegroundColor Gray
$healthResponseJson = '{"status": "healthy", "timestamp": "$context.requestTime", "region": "us-east-1", "endpoint": "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod", "cors": "enabled"}'
aws apigateway put-integration-response --rest-api-id $API_ID --resource-id $healthResourceId --http-method GET --status-code 200 --response-templates "application/json=$healthResponseJson" --response-parameters 'method.response.header.Access-Control-Allow-Origin=*'

# Fix OPTIONS integration
Write-Host "Fixing OPTIONS integration..." -ForegroundColor Gray
aws apigateway put-integration --rest-api-id $API_ID --resource-id $healthResourceId --http-method OPTIONS --type MOCK --request-templates 'application/json={"statusCode": 200}'

# Fix OPTIONS integration response
aws apigateway put-integration-response --rest-api-id $API_ID --resource-id $healthResourceId --http-method OPTIONS --status-code 200 --response-parameters 'method.response.header.Access-Control-Allow-Headers=Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Requested-With,method.response.header.Access-Control-Allow-Methods=GET,OPTIONS,method.response.header.Access-Control-Allow-Origin=*'

# Deploy API Gateway
Write-Host "Deploying API Gateway..." -ForegroundColor Yellow
aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod --description "Fixed health endpoint integration"

Write-Host "✅ Health endpoint fixed and deployed!" -ForegroundColor Green