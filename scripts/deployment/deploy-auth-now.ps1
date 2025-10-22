Write-Host "🚀 Deploying auth handler fix..." -ForegroundColor Green

Set-Location lambda/auth

Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
npm install

Write-Host "📦 Creating deployment package..." -ForegroundColor Yellow
Compress-Archive -Path "auth-handler.ts", "cognito-helper.ts", "package.json", "node_modules" -DestinationPath "auth-handler.zip" -Force

Write-Host "☁️ Deploying to AWS Lambda..." -ForegroundColor Yellow
aws lambda update-function-code --function-name devops-auth-lambda --zip-file fileb://auth-handler.zip

Write-Host "🧪 Testing updated function..." -ForegroundColor Yellow
Set-Location ..\..\
node debug-frontend-request.js

Write-Host "🎉 Deployment complete!" -ForegroundColor Green