# Simple deployment of auth handler fix

Write-Host "🚀 Deploying auth handler fix..." -ForegroundColor Green

# Navigate to lambda/auth directory
cd lambda/auth

# Install dependencies if needed
if (-not (Test-Path "node_modules")) {
    Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
    npm install
}

# Create a simple deployment package with just the source files
Write-Host "📦 Creating deployment package..." -ForegroundColor Yellow

# Create temp directory for deployment
$tempDir = "temp-deploy"
if (Test-Path $tempDir) {
    Remove-Item -Recurse -Force $tempDir
}
New-Item -ItemType Directory -Path $tempDir

# Copy source files
Copy-Item "*.ts" $tempDir
Copy-Item "package.json" $tempDir

# Copy node_modules
if (Test-Path "node_modules") {
    Copy-Item -Recurse "node_modules" $tempDir
}

# Create zip file
Compress-Archive -Path "$tempDir\*" -DestinationPath "auth-handler.zip" -Force

# Clean up temp directory
Remove-Item -Recurse -Force $tempDir

# Deploy to AWS Lambda
Write-Host "☁️ Deploying to AWS Lambda..." -ForegroundColor Yellow
aws lambda update-function-code --function-name devops-auth-lambda --zip-file fileb://auth-handler.zip

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Lambda function updated successfully!" -ForegroundColor Green
    
    # Clean up zip file
    Remove-Item "auth-handler.zip"
    
    # Test the updated function
    Write-Host "🧪 Testing updated function..." -ForegroundColor Yellow
    cd ..\..\
    node debug-frontend-request.js
    
} else {
    Write-Host "❌ Lambda deployment failed!" -ForegroundColor Red
    exit 1
}

Write-Host "🎉 Auth fix deployment complete!" -ForegroundColor Green