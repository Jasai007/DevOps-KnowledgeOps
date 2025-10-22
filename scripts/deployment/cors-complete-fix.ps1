Write-Host "Complete CORS fix with templates..." -ForegroundColor Green

$apiId = "66a22b8wlb"
$resourceId = "tdrqda"

Write-Host "Updating integration response with templates..." -ForegroundColor Yellow
aws apigateway put-integration-response --rest-api-id $apiId --resource-id $resourceId --http-method OPTIONS --status-code 200 --response-parameters file://temp/response-params.json --response-templates file://temp/response-templates.json

Write-Host "Deploying..." -ForegroundColor Yellow
aws apigateway create-deployment --rest-api-id $apiId --stage-name prod

Write-Host "Waiting for deployment..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host "Testing OPTIONS..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/session" -Method OPTIONS
    Write-Host "SUCCESS! Status:" $response.StatusCode -ForegroundColor Green
    Write-Host "Headers:" -ForegroundColor Cyan
    $response.Headers.GetEnumerator() | Where-Object { $_.Key -like "*Access-Control*" } | ForEach-Object { Write-Host "  $($_.Key): $($_.Value)" }
} catch {
    Write-Host "Still failed:" $_.Exception.Message -ForegroundColor Red
}

Write-Host "Testing in browser..." -ForegroundColor Yellow
start scripts/deployment/test-session-browser.html

Write-Host "CORS fix complete!" -ForegroundColor Green