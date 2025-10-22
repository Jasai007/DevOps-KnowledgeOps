Write-Host "Quick CORS fix for session endpoint..." -ForegroundColor Green

# Direct AWS CLI commands with proper escaping
$apiId = "66a22b8wlb"
$resourceId = "tdrqda"

Write-Host "Adding mock integration..."
aws apigateway put-integration --rest-api-id $apiId --resource-id $resourceId --http-method OPTIONS --type MOCK --integration-http-method OPTIONS

Write-Host "Adding integration response with CORS headers..."
aws apigateway put-integration-response --rest-api-id $apiId --resource-id $resourceId --http-method OPTIONS --status-code 200 --response-parameters '{\"method.response.header.Access-Control-Allow-Origin\":\"*\",\"method.response.header.Access-Control-Allow-Methods\":\"GET,POST,OPTIONS\",\"method.response.header.Access-Control-Allow-Headers\":\"Content-Type,Authorization\"}'

Write-Host "Deploying changes..."
aws apigateway create-deployment --rest-api-id $apiId --stage-name prod

Write-Host "Waiting for deployment..."
Start-Sleep -Seconds 5

Write-Host "Testing CORS..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/session" -Method OPTIONS
    Write-Host "SUCCESS! CORS is working. Status:" $response.StatusCode -ForegroundColor Green
} catch {
    Write-Host "CORS still not working:" $_.Exception.Message -ForegroundColor Red
}

Write-Host "Done!" -ForegroundColor Green