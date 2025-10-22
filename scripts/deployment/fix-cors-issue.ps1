# Fix CORS Issue for Frontend Development
$API_ID = "66a22b8wlb"

Write-Host "🔧 Fixing CORS configuration for local development..." -ForegroundColor Cyan

# Get auth resource ID
$resources = aws apigateway get-resources --rest-api-id $API_ID --output json | ConvertFrom-Json
$authResourceId = ($resources.items | Where-Object { $_.pathPart -eq "auth" }).id

Write-Host "Auth Resource ID: $authResourceId" -ForegroundColor Gray

# Add OPTIONS method for CORS preflight
Write-Host "Adding OPTIONS method for CORS..." -ForegroundColor Yellow
aws apigateway put-method --rest-api-id $API_ID --resource-id $authResourceId --http-method OPTIONS --authorization-type NONE --no-cli-pager 2>$null

# Add CORS integration for OPTIONS
Write-Host "Adding CORS integration..." -ForegroundColor Yellow
aws apigateway put-integration --rest-api-id $API_ID --resource-id $authResourceId --http-method OPTIONS --type MOCK --integration-http-method OPTIONS --request-templates '{"application/json":"{\"statusCode\": 200}"}' --no-cli-pager 2>$null

# Add method response for OPTIONS
Write-Host "Adding method response..." -ForegroundColor Yellow
aws apigateway put-method-response --rest-api-id $API_ID --resource-id $authResourceId --http-method OPTIONS --status-code 200 --response-parameters '{"method.response.header.Access-Control-Allow-Headers":false,"method.response.header.Access-Control-Allow-Methods":false,"method.response.header.Access-Control-Allow-Origin":false}' --no-cli-pager 2>$null

# Add integration response for OPTIONS
Write-Host "Adding integration response..." -ForegroundColor Yellow
aws apigateway put-integration-response --rest-api-id $API_ID --resource-id $authResourceId --http-method OPTIONS --status-code 200 --response-parameters '{"method.response.header.Access-Control-Allow-Headers":"'"'"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"'"'","method.response.header.Access-Control-Allow-Methods":"'"'"'GET,POST,OPTIONS'"'"'","method.response.header.Access-Control-Allow-Origin":"'"'"'*'"'"'"}' --no-cli-pager 2>$null

# Update POST method response to include CORS headers
Write-Host "Updating POST method response..." -ForegroundColor Yellow
aws apigateway put-method-response --rest-api-id $API_ID --resource-id $authResourceId --http-method POST --status-code 200 --response-parameters '{"method.response.header.Access-Control-Allow-Origin":false}' --no-cli-pager 2>$null

# Deploy the changes
Write-Host "Deploying API changes..." -ForegroundColor Yellow
aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod --stage-description "Fixed CORS for local development" --no-cli-pager

Write-Host "✅ CORS configuration updated!" -ForegroundColor Green