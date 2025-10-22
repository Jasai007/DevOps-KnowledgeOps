# Simple deployment of auth handler fix

Write-Host "🚀 Deploying auth handler fix..." -ForegroundColor Green

# Navigate to lambda/auth directory
Set-Location lambda/auth

# Install dependencies if needed
if (-not (Test-Path "node_modules")) {
    Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
    npm install
}

# Create deployment package
Write-Host "📦 Creating deployment package..." -ForegroundColor Yellow

# Remove old zip if exists
if (Test-Path "auth-handler.zip") {
    Remove-Item "auth-handler.zip"
}

# Create zip with all necessary files
Compress-Archive -Path "auth-handler.ts", "cognito-helper.ts", "package.json", "node_modules" -DestinationPath "auth-handler.zip" -Force

# Deploy to AWS Lambda
Write-Host "☁️ Deploying to AWS Lambda..." -ForegroundColor Yellow
aws lambda update-function-code --function-name devops-auth-lambda --zip-file fileb://auth-handler.zip

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Lambda function updated successfully!" -ForegroundColor Green
    
    # Clean up zip file
    Remove-Item "auth-handler.zip"
    
    # Test the updated function
    Write-Host "🧪 Testing updated function..." -ForegroundColor Yellow
    Set-Location ..\..\
    node debug-frontend-request.js
    
} else {
    Write-Host "❌ Lambda deployment failed!" -ForegroundColor Red
    Set-Location ..\..\
    exit 1
}

Write-Host "🎉 Auth fix deployment complete!" -ForegroundColor Green