Write-Host "Complete CORS fix for session endpoint..." -ForegroundColor Green

$apiId = "66a22b8wlb"
$resourceId = "tdrqda"

Write-Host "Deleting existing OPTIONS method..." -ForegroundColor Yellow
aws apigateway delete-method --rest-api-id $apiId --resource-id $resourceId --http-method OPTIONS 2>$null

Write-Host "Adding OPTIONS method..." -ForegroundColor Yellow
aws apigateway put-method --rest-api-id $apiId --resource-id $resourceId --http-method OPTIONS --authorization-type NONE

Write-Host "Adding method response..." -ForegroundColor Yellow
aws apigateway put-method-response --rest-api-id $apiId --resource-id $resourceId --http-method OPTIONS --status-code 200 --response-parameters '{\"method.response.header.Access-Control-Allow-Origin\":false,\"method.response.header.Access-Control-Allow-Methods\":false,\"method.response.header.Access-Control-Allow-Headers\":false}'

Write-Host "Adding mock integration..." -ForegroundColor Yellow
aws apigateway put-integration --rest-api-id $apiId --resource-id $resourceId --http-method OPTIONS --type MOCK --passthrough-behavior WHEN_NO_MATCH --request-templates '{\"application/json\":\"{\\\"statusCode\\\": 200}\"}'

Write-Host "Adding integration response..." -ForegroundColor Yellow
aws apigateway put-integration-response --rest-api-id $apiId --resource-id $resourceId --http-method OPTIONS --status-code 200 --response-parameters '{\"method.response.header.Access-Control-Allow-Origin\":\"*\",\"method.response.header.Access-Control-Allow-Methods\":\"GET,POST,OPTIONS\",\"method.response.header.Access-Control-Allow-Headers\":\"Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token\"}'

Write-Host "Deploying changes..." -ForegroundColor Yellow
aws apigateway create-deployment --rest-api-id $apiId --stage-name prod

Write-Host "Waiting for deployment..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host "Testing OPTIONS request..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/session" -Method OPTIONS
    Write-Host "OPTIONS SUCCESS! Status:" $response.StatusCode -ForegroundColor Green
} catch {
    Write-Host "OPTIONS failed:" $_.Exception.Message -ForegroundColor Red
}

Write-Host "Testing POST request..." -ForegroundColor Yellow
try {
    $postResponse = Invoke-RestMethod -Uri "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/session" -Method POST -Body '{"action":"create"}' -ContentType "application/json"
    Write-Host "POST SUCCESS!" -ForegroundColor Green
} catch {
    Write-Host "POST failed:" $_.Exception.Message -ForegroundColor Red
}

Write-Host "CORS fix complete! Test the browser now." -ForegroundColor Green