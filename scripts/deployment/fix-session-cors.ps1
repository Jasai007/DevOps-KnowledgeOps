Write-Host "🚀 Fixing session CORS..." -ForegroundColor Green

Set-Location lambda/session

Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
npm install

Write-Host "📦 Creating deployment package..." -ForegroundColor Yellow
Compress-Archive -Path "session-handler.ts", "session-manager.ts", "package.json", "node_modules" -DestinationPath "session-handler.zip" -Force

Write-Host "☁️ Deploying to AWS Lambda..." -ForegroundColor Yellow
aws lambda update-function-code --function-name simple-session-handler --zip-file fileb://session-handler.zip

Write-Host "🧪 Testing session endpoint..." -ForegroundColor Yellow
Set-Location ..\..\

$testPayload = '{"action":"create"}'
$response = Invoke-RestMethod -Uri "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/session" -Method POST -Body $testPayload -ContentType "application/json"
Write-Host "Response:" ($response | ConvertTo-Json)

Write-Host "✅ Session fix complete!" -ForegroundColor Green