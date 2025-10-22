# Deploy the updated auth handler to fix the 401 error

Write-Host "🚀 Deploying updated auth handler..." -ForegroundColor Green

# Build the Lambda function
Write-Host "📦 Building Lambda function..." -ForegroundColor Yellow
cd lambda/auth
npm run build

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}

# Create deployment package
Write-Host "📦 Creating deployment package..." -ForegroundColor Yellow
Compress-Archive -Path dist\*, node_modules\* -DestinationPath auth-handler.zip -Force

# Deploy to AWS Lambda
Write-Host "☁️ Deploying to AWS Lambda..." -ForegroundColor Yellow
aws lambda update-function-code --function-name devops-auth-lambda --zip-file fileb://auth-handler.zip

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Lambda function updated successfully!" -ForegroundColor Green
    
    # Test the updated function
    Write-Host "🧪 Testing updated function..." -ForegroundColor Yellow
    cd ..\..\
    node debug-frontend-request.js
    
} else {
    Write-Host "❌ Lambda deployment failed!" -ForegroundColor Red
    exit 1
}

Write-Host "🎉 Auth fix deployment complete!" -ForegroundColor Green