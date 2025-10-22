Write-Host "🔧 Complete CORS fix for session endpoint..." -ForegroundColor Green

$apiId = "66a22b8wlb"
$resourceId = "tdrqda"

Write-Host "Step 1: Delete existing OPTIONS method if it exists..." -ForegroundColor Yellow
aws apigateway delete-method --rest-api-id $apiId --resource-id $resourceId --http-method OPTIONS 2>$null

Write-Host "Step 2: Add OPTIONS method..." -ForegroundColor Yellow
aws apigateway put-method --rest-api-id $apiId --resource-id $resourceId --http-method OPTIONS --authorization-type NONE

Write-Host "Step 3: Add method response for OPTIONS..." -ForegroundColor Yellow
aws apigateway put-method-response --rest-api-id $apiId --resource-id $resourceId --http-method OPTIONS --status-code 200 --response-parameters '{\"method.response.header.Access-Control-Allow-Origin\":false,\"method.response.header.Access-Control-Allow-Methods\":false,\"method.response.header.Access-Control-Allow-Headers\":false}'

Write-Host "Step 4: Add mock integration..." -ForegroundColor Yellow
aws apigateway put-integration --rest-api-id $apiId --resource-id $resourceId --http-method OPTIONS --type MOCK --passthrough-behavior WHEN_NO_MATCH --request-templates '{\"application/json\":\"{\\\"statusCode\\\": 200}\"}'

Write-Host "Step 5: Add integration response..." -ForegroundColor Yellow
aws apigateway put-integration-response --rest-api-id $apiId --resource-id $resourceId --http-method OPTIONS --status-code 200 --response-parameters '{\"method.response.header.Access-Control-Allow-Origin\":\"*\",\"method.response.header.Access-Control-Allow-Methods\":\"GET,POST,OPTIONS\",\"method.response.header.Access-Control-Allow-Headers\":\"Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token\"}'

Write-Host "Step 6: Deploy changes..." -ForegroundColor Yellow
aws apigateway create-deployment --rest-api-id $apiId --stage-name prod

Write-Host "Step 7: Wait for deployment..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host "Step 8: Test OPTIONS request..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/session" -Method OPTIONS
    Write-Host "✅ OPTIONS SUCCESS! Status:" $response.StatusCode -ForegroundColor Green
    Write-Host "CORS Headers:" -ForegroundColor Cyan
    $response.Headers.GetEnumerator() | Where-Object { $_.Key -like "*Access-Control*" } | ForEach-Object { Write-Host "  $($_.Key): $($_.Value)" }
} catch {
    Write-Host "❌ OPTIONS still failing:" $_.Exception.Message -ForegroundColor Red
}

Write-Host "Step 9: Test POST request..." -ForegroundColor Yellow
try {
    $postResponse = Invoke-RestMethod -Uri "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/session" -Method POST -Body '{"action":"create"}' -ContentType "application/json"
    Write-Host "✅ POST SUCCESS!" -ForegroundColor Green
    Write-Host "Response:" ($postResponse | ConvertTo-Json)
} catch {
    Write-Host "❌ POST failing:" $_.Exception.Message -ForegroundColor Red
}

Write-Host "🎉 CORS configuration complete!" -ForegroundColor Green
Write-Host "Please test the browser now." -ForegroundColor Cyan