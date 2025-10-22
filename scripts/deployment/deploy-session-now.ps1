Write-Host "Deploying simple session handler..." -ForegroundColor Green

Set-Location lambda/session

Write-Host "Creating deployment package..." -ForegroundColor Yellow
Compress-Archive -Path "simple-session-handler.ts", "package.json" -DestinationPath "simple-session.zip" -Force

Write-Host "Deploying to Lambda..." -ForegroundColor Yellow
aws lambda update-function-code --function-name simple-session-handler --zip-file fileb://simple-session.zip

Write-Host "Updating handler configuration..." -ForegroundColor Yellow
aws lambda update-function-configuration --function-name simple-session-handler --handler simple-session-handler.handler

Remove-Item "simple-session.zip" -Force

Write-Host "Testing function..." -ForegroundColor Yellow
Set-Location ..\..\

$testPayload = '{"action":"create"}'
$response = Invoke-RestMethod -Uri "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/session" -Method POST -Body $testPayload -ContentType "application/json"
Write-Host "Response:" ($response | ConvertTo-Json)

Write-Host "Deployment complete!" -ForegroundColor Green