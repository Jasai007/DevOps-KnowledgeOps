Write-Host "Deploying JavaScript session handler..." -ForegroundColor Green

Set-Location lambda/session

Write-Host "Creating deployment package..." -ForegroundColor Yellow
Compress-Archive -Path "simple-session-handler.js" -DestinationPath "js-session.zip" -Force

Write-Host "Deploying to Lambda..." -ForegroundColor Yellow
aws lambda update-function-code --function-name simple-session-handler --zip-file fileb://js-session.zip

Write-Host "Updating handler configuration..." -ForegroundColor Yellow
aws lambda update-function-configuration --function-name simple-session-handler --handler simple-session-handler.handler

Remove-Item "js-session.zip" -Force

Write-Host "Waiting for deployment..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

Write-Host "Testing function..." -ForegroundColor Yellow
Set-Location ..\..\

$testPayload = '{"action":"create"}'
try {
    $response = Invoke-RestMethod -Uri "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/session" -Method POST -Body $testPayload -ContentType "application/json"
    Write-Host "SUCCESS! Response:" ($response | ConvertTo-Json) -ForegroundColor Green
} catch {
    Write-Host "FAILED! Error:" $_.Exception.Message -ForegroundColor Red
}

Write-Host "Testing OPTIONS request..." -ForegroundColor Yellow
try {
    $optionsResponse = Invoke-WebRequest -Uri "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/session" -Method OPTIONS
    Write-Host "OPTIONS SUCCESS! Status:" $optionsResponse.StatusCode -ForegroundColor Green
} catch {
    Write-Host "OPTIONS FAILED! Error:" $_.Exception.Message -ForegroundColor Red
}

Write-Host "Deployment complete!" -ForegroundColor Green