# Deploy Lambda Architecture Script
# This deploys the proper serverless architecture instead of using Express server

Write-Host "🚀 DevOps KnowledgeOps - Lambda Architecture Deployment" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan

# Check prerequisites
Write-Host "`n🔍 Checking prerequisites..." -ForegroundColor Yellow

# Check AWS CLI
try {
    $awsVersion = aws --version
    Write-Host "✅ AWS CLI: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS CLI not found. Please install AWS CLI first." -ForegroundColor Red
    Write-Host "   Download from: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    exit 1
}

# Check CDK
try {
    $cdkVersion = cdk --version
    Write-Host "✅ AWS CDK: $cdkVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS CDK not found. Installing..." -ForegroundColor Yellow
    npm install -g aws-cdk
}

# Check Node.js
try {
    $nodeVersion = node --version
    Write-Host "✅ Node.js: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js not found. Please install Node.js first." -ForegroundColor Red
    exit 1
}

Write-Host "`n📦 Building Lambda functions..." -ForegroundColor Yellow

# Build Lambda functions
Set-Location lambda
npm install
npm run build

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Lambda build failed" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Lambda functions built successfully" -ForegroundColor Green

# Deploy infrastructure
Write-Host "`n🏗️ Deploying infrastructure..." -ForegroundColor Yellow
Set-Location ../infrastructure

npm install
cdk bootstrap

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ CDK bootstrap failed" -ForegroundColor Red
    exit 1
}

cdk deploy --require-approval never

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ CDK deployment failed" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Infrastructure deployed successfully" -ForegroundColor Green

# Get outputs
Write-Host "`n📋 Getting deployment outputs..." -ForegroundColor Yellow
$outputs = cdk output --json | ConvertFrom-Json

Write-Host "`n🎉 Deployment Complete!" -ForegroundColor Green
Write-Host "======================" -ForegroundColor Green

Write-Host "`n📊 Deployment Information:" -ForegroundColor Cyan
Write-Host "API Gateway URL: $($outputs.ApiGatewayUrl)" -ForegroundColor White
Write-Host "User Pool ID: $($outputs.UserPoolId)" -ForegroundColor White
Write-Host "User Pool Client ID: $($outputs.UserPoolClientId)" -ForegroundColor White
Write-Host "Knowledge Bucket: $($outputs.KnowledgeBucketName)" -ForegroundColor White
Write-Host "Chat Table: $($outputs.ChatTableName)" -ForegroundColor White

Write-Host "`n🔧 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Update frontend API_BASE_URL to: $($outputs.ApiGatewayUrl)" -ForegroundColor Gray
Write-Host "2. Update Cognito configuration with new User Pool details" -ForegroundColor Gray
Write-Host "3. Test the Lambda-based API endpoints" -ForegroundColor Gray
Write-Host "4. Upload knowledge base documents to S3 bucket" -ForegroundColor Gray

Write-Host "`n✅ Lambda Architecture Benefits:" -ForegroundColor Green
Write-Host "- Proper user session isolation with DynamoDB" -ForegroundColor White
Write-Host "- Serverless scalability and cost efficiency" -ForegroundColor White
Write-Host "- Native AWS service integration" -ForegroundColor White
Write-Host "- No more 403 errors with proper authentication" -ForegroundColor White
Write-Host "- Persistent session storage across deployments" -ForegroundColor White

Set-Location ..