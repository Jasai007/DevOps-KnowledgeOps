Write-Host "🚀 Deploying chat Lambda function..." -ForegroundColor Green

Set-Location lambda/chat

Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
npm install

Write-Host "📦 Creating deployment package..." -ForegroundColor Yellow
Compress-Archive -Path "chat-handler.js", "agentcore-gateway.js", "package.json", "node_modules" -DestinationPath "chat-lambda.zip" -Force

Write-Host "☁️ Deploying to AWS Lambda..." -ForegroundColor Yellow
aws lambda update-function-code --function-name agentcore-simple-chat --zip-file fileb://chat-lambda.zip

Write-Host "🔧 Updating handler configuration..." -ForegroundColor Yellow
aws lambda update-function-configuration --function-name agentcore-simple-chat --handler chat-handler.handler

Remove-Item "chat-lambda.zip" -Force

Write-Host "⏳ Waiting for deployment..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host "🧪 Testing chat function..." -ForegroundColor Yellow
Set-Location ..\..\

$testPayload = '{"message":"Hello, I need help with Kubernetes deployment","sessionId":"test-session-123"}'
Write-Host "Test payload: $testPayload"

try {
    $response = Invoke-RestMethod -Uri "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/chat" -Method POST -Body $testPayload -ContentType "application/json"
    Write-Host "✅ Chat test successful!" -ForegroundColor Green
    Write-Host "Response preview:" ($response.response.Substring(0, [Math]::Min(200, $response.response.Length)) + "...")
    Write-Host "Metadata:" ($response.metadata | ConvertTo-Json)
} catch {
    Write-Host "❌ Chat test failed:" -ForegroundColor Red
    Write-Host $_.Exception.Message
}

Write-Host "🎉 Chat Lambda deployment complete!" -ForegroundColor Green