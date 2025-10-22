# Simple Production Deployment
Write-Host "Deploying Production-Ready DevOps Agent" -ForegroundColor Cyan

# Step 1: Create and deploy Lambda packages
Write-Host "`n1. Creating deployment packages..." -ForegroundColor Yellow
./scripts/deployment/simple-cors-fix.ps1

# Step 2: Deploy to Lambda
Write-Host "`n2. Deploying Lambda functions..." -ForegroundColor Yellow

Write-Host "Deploying chat function..." -ForegroundColor Gray
aws lambda update-function-code --function-name agentcore-simple-chat --zip-file fileb://lambda-chat-cors.zip

Write-Host "Deploying auth function..." -ForegroundColor Gray  
aws lambda update-function-code --function-name cors-auth-final --zip-file fileb://lambda-auth-cors.zip

Write-Host "Deploying session function..." -ForegroundColor Gray
aws lambda update-function-code --function-name simple-session-handler --zip-file fileb://lambda-session-cors.zip

# Step 3: Update frontend for production
Write-Host "`n3. Updating frontend configuration..." -ForegroundColor Yellow

# Update .env file
$envContent = @"
REACT_APP_API_URL=https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod
REACT_APP_USER_POOL_ID=us-east-1_QVdUR725D
REACT_APP_USER_POOL_CLIENT_ID=7a283i8pqhq7h1k88me51gsefo
"@

$envContent | Set-Content "frontend/.env"
Write-Host "Frontend .env updated for production" -ForegroundColor Green

# Update api.ts
$apiContent = Get-Content "frontend/src/services/api.ts" -Raw
$newApiContent = $apiContent -replace "const API_BASE_URL = 'http://localhost:3001';", "const API_BASE_URL = process.env.REACT_APP_API_URL || 'https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod';"
$newApiContent | Set-Content "frontend/src/services/api.ts"
Write-Host "API service updated for production" -ForegroundColor Green

# Step 4: Build frontend
Write-Host "`n4. Building frontend..." -ForegroundColor Yellow
Push-Location frontend
npm run build
Pop-Location

# Step 5: Test deployment
Write-Host "`n5. Testing deployment..." -ForegroundColor Yellow
./scripts/deployment/test-api-endpoints.ps1

# Cleanup
Write-Host "`n6. Cleaning up..." -ForegroundColor Yellow
Remove-Item lambda-chat-cors.zip, lambda-auth-cors.zip, lambda-session-cors.zip -ErrorAction SilentlyContinue

Write-Host "`nDeployment Complete!" -ForegroundColor Cyan
Write-Host "Frontend build ready in: frontend/build/" -ForegroundColor Green
Write-Host "API Gateway URL: https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod" -ForegroundColor Green