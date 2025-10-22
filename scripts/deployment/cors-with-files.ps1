Write-Host "CORS fix using JSON files..." -ForegroundColor Green

$apiId = "66a22b8wlb"
$resourceId = "tdrqda"

Write-Host "Adding mock integration with file..." -ForegroundColor Yellow
aws apigateway put-integration --rest-api-id $apiId --resource-id $resourceId --http-method OPTIONS --type MOCK --passthrough-behavior WHEN_NO_MATCH --request-templates file://temp/integration-template.json

Write-Host "Adding integration response with file..." -ForegroundColor Yellow
aws apigateway put-integration-response --rest-api-id $apiId --resource-id $resourceId --http-method OPTIONS --status-code 200 --response-parameters file://temp/response-params.json

Write-Host "Deploying..." -ForegroundColor Yellow
aws apigateway create-deployment --rest-api-id $apiId --stage-name prod

Write-Host "Waiting..." -ForegroundColor Yellow
Start-Sleep -Seconds 8

Write-Host "Testing OPTIONS..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/session" -Method OPTIONS
    Write-Host "SUCCESS! Status:" $response.StatusCode -ForegroundColor Green
} catch {
    Write-Host "Failed:" $_.Exception.Message -ForegroundColor Red
}

Write-Host "Done!" -ForegroundColor Green