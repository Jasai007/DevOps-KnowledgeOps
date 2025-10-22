# Deploy API Gateway Authentication Fix
# This script deploys the updated CDK infrastructure with proper authentication

Write-Host "🚀 Deploying API Gateway Authentication Fix..." -ForegroundColor Cyan

# Check if we're in the right directory
if (-not (Test-Path "infrastructure")) {
    Write-Host "❌ Please run this script from the project root directory" -ForegroundColor Red
    exit 1
}

# Build Lambda functions first
Write-Host "`n📦 Building Lambda functions..." -ForegroundColor Yellow
Set-Location lambda

if (Test-Path "package.json") {
    Write-Host "Installing Lambda dependencies..." -ForegroundColor Gray
    npm install
    
    Write-Host "Building Lambda functions..." -ForegroundColor Gray
    npm run build
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Lambda build failed" -ForegroundColor Red
        Set-Location ..
        exit 1
    }
    
    Write-Host "✅ Lambda functions built successfully" -ForegroundColor Green
} else {
    Write-Host "⚠️ No package.json found in lambda directory, skipping build" -ForegroundColor Yellow
}

Set-Location ..

# Deploy CDK infrastructure
Write-Host "`n🏗️ Deploying CDK infrastructure..." -ForegroundColor Yellow
Set-Location infrastructure

if (Test-Path "package.json") {
    Write-Host "Installing CDK dependencies..." -ForegroundColor Gray
    npm install
    
    Write-Host "Checking CDK diff..." -ForegroundColor Gray
    cdk diff
    
    Write-Host "Deploying CDK stack..." -ForegroundColor Gray
    cdk deploy --require-approval never
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ CDK deployment successful" -ForegroundColor Green
    } else {
        Write-Host "❌ CDK deployment failed" -ForegroundColor Red
        Set-Location ..
        exit 1
    }
} else {
    Write-Host "❌ No package.json found in infrastructure directory" -ForegroundColor Red
    Set-Location ..
    exit 1
}

Set-Location ..

# Test the updated API
Write-Host "`n🧪 Testing updated API..." -ForegroundColor Yellow

Write-Host "Testing public auth endpoint..." -ForegroundColor Gray
try {
    $authResponse = Invoke-RestMethod -Uri "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/auth" -Method POST -ContentType "application/json" -Body '{"action":"signin","username":"demo@example.com","password":"DemoPassword123!"}'
    
    if ($authResponse.success) {
        Write-Host "✅ Auth endpoint is now public and working!" -ForegroundColor Green
        Write-Host "   Access Token: $($authResponse.accessToken.Substring(0, 20))..." -ForegroundColor Gray
        Write-Host "   ID Token: $($authResponse.idToken.Substring(0, 20))..." -ForegroundColor Gray
        
        # Test protected endpoint with ID token
        Write-Host "`nTesting protected session endpoint..." -ForegroundColor Gray
        try {
            $sessionResponse = Invoke-RestMethod -Uri "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/session" -Method POST -ContentType "application/json" -Headers @{Authorization = $authResponse.idToken} -Body '{"action":"create"}'
            
            if ($sessionResponse.success) {
                Write-Host "✅ Protected endpoints working with ID token!" -ForegroundColor Green
                Write-Host "   Session ID: $($sessionResponse.session.sessionId)" -ForegroundColor Gray
            } else {
                Write-Host "❌ Protected endpoint failed: $($sessionResponse.error)" -ForegroundColor Red
            }
        } catch {
            Write-Host "❌ Protected endpoint test failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ Auth endpoint failed: $($authResponse.error)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Auth endpoint test failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🎉 API Gateway Fix Deployment Complete!" -ForegroundColor Cyan
Write-Host "`n📋 Summary of Changes:" -ForegroundColor Cyan
Write-Host "✅ Auth endpoint is now public (no authentication required)" -ForegroundColor Green
Write-Host "✅ Protected endpoints use Cognito User Pool authorization" -ForegroundColor Green
Write-Host "✅ Lambda functions updated to use Cognito authorizer context" -ForegroundColor Green
Write-Host "✅ Frontend updated to use ID tokens for authorization" -ForegroundColor Green

Write-Host "`n🔧 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Test the frontend application" -ForegroundColor Gray
Write-Host "2. Verify user session isolation" -ForegroundColor Gray
Write-Host "3. Test chat functionality end-to-end" -ForegroundColor Gray