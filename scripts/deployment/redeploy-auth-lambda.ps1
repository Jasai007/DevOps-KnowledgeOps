# Redeploy Auth Lambda Function
Write-Host "Redeploying Auth Lambda Function" -ForegroundColor Cyan

# Create deployment package
Write-Host "Creating deployment package..." -ForegroundColor Yellow
Set-Location lambda/auth

# Install dependencies
npm install

# Create zip file
if (Test-Path "auth-lambda.zip") {
    Remove-Item "auth-lambda.zip"
}

# Create zip with PowerShell
Compress-Archive -Path "auth-handler.js", "node_modules", "package.json" -DestinationPath "auth-lambda.zip" -Force

Write-Host "Deployment package created" -ForegroundColor Green

# Update Lambda function
Write-Host "Updating Lambda function code..." -ForegroundColor Yellow
aws lambda update-function-code --function-name cors-auth-final --zip-file fileb://auth-lambda.zip

# Update environment variables to ensure they're set
Write-Host "Updating environment variables..." -ForegroundColor Yellow
aws lambda update-function-configuration --function-name cors-auth-final --environment Variables='{USER_POOL_ID=us-east-1_QVdUR725D,USER_POOL_CLIENT_ID=7a283i8pqhq7h1k88me51gsefo,USER_POOL_CLIENT_SECRET=vr0eledlg9ok3db66t3ktpmq7d0095o0a1moqv78ikjsv0mnp8m}'

Write-Host "Lambda function updated successfully" -ForegroundColor Green

# Return to root directory
Set-Location ../..

Write-Host "Auth Lambda redeployment complete!" -ForegroundColor Cyan