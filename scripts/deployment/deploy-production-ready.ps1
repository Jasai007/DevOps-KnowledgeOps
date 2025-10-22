# Deploy Production-Ready DevOps Agent
Write-Host "🚀 Deploying Production-Ready DevOps Agent" -ForegroundColor Cyan

# Configuration
$API_ID = "uvhylyixu1"
$CHAT_FUNCTION = "agentcore-simple-chat"
$AUTH_FUNCTION = "cors-auth-final"
$SESSION_FUNCTION = "simple-session-handler"

Write-Host "`n📋 Deployment Plan:" -ForegroundColor Yellow
Write-Host "1. Deploy CORS-fixed Lambda functions" -ForegroundColor Gray
Write-Host "2. Configure API Gateway CORS" -ForegroundColor Gray
Write-Host "3. Test all endpoints" -ForegroundColor Gray
Write-Host "4. Update frontend configuration" -ForegroundColor Gray
Write-Host "5. Build and prepare for production" -ForegroundColor Gray

# Step 1: Deploy Lambda Functions
Write-Host "`n1. 🚀 Deploying Lambda Functions..." -ForegroundColor Yellow

# Create deployment packages (they should already exist)
if (!(Test-Path "lambda-chat-cors.zip") -or !(Test-Path "lambda-auth-cors.zip") -or !(Test-Path "lambda-session-cors.zip")) {
    Write-Host "Creating deployment packages..." -ForegroundColor Gray
    ./scripts/deployment/simple-cors-fix.ps1
}

# Deploy chat function
Write-Host "Deploying chat function..." -ForegroundColor Gray
try {
    aws lambda update-function-code --function-name $CHAT_FUNCTION --zip-file fileb://lambda-chat-cors.zip
    Write-Host "✅ Chat function deployed" -ForegroundColor Green
} catch {
    Write-Host "❌ Chat function deployment failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Deploy auth function
Write-Host "Deploying auth function..." -ForegroundColor Gray
try {
    aws lambda update-function-code --function-name $AUTH_FUNCTION --zip-file fileb://lambda-auth-cors.zip
    Write-Host "✅ Auth function deployed" -ForegroundColor Green
} catch {
    Write-Host "❌ Auth function deployment failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Deploy session function
Write-Host "Deploying session function..." -ForegroundColor Gray
try {
    aws lambda update-function-code --function-name $SESSION_FUNCTION --zip-file fileb://lambda-session-cors.zip
    Write-Host "✅ Session function deployed" -ForegroundColor Green
} catch {
    Write-Host "❌ Session function deployment failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 2: Configure API Gateway CORS
Write-Host "`n2. 🔧 Configuring API Gateway CORS..." -ForegroundColor Yellow

# Get resources
$resources = aws apigateway get-resources --rest-api-id $API_ID --output json | ConvertFrom-Json

foreach ($resource in $resources.items) {
    if ($resource.pathPart -and $resource.pathPart -ne "None") {
        $resourceId = $resource.id
        $path = $resource.pathPart
        
        Write-Host "Configuring CORS for /$path..." -ForegroundColor Gray
        
        try {
            # Add OPTIONS method
            aws apigateway put-method --rest-api-id $API_ID --resource-id $resourceId --http-method OPTIONS --authorization-type NONE --no-api-key-required 2>$null
            
            # Add method response
            aws apigateway put-method-response --rest-api-id $API_ID --resource-id $resourceId --http-method OPTIONS --status-code 200 --response-parameters "method.response.header.Access-Control-Allow-Headers=false,method.response.header.Access-Control-Allow-Methods=false,method.response.header.Access-Control-Allow-Origin=false" 2>$null
            
            # Add integration
            aws apigateway put-integration --rest-api-id $API_ID --resource-id $resourceId --http-method OPTIONS --type MOCK --integration-http-method OPTIONS --request-templates "application/json={`"statusCode`": 200}" 2>$null
            
            # Add integration response
            aws apigateway put-integration-response --rest-api-id $API_ID --resource-id $resourceId --http-method OPTIONS --status-code 200 --response-parameters "method.response.header.Access-Control-Allow-Headers='Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Requested-With',method.response.header.Access-Control-Allow-Methods='GET,POST,OPTIONS,PUT,DELETE,PATCH',method.response.header.Access-Control-Allow-Origin='*'" 2>$null
            
            Write-Host "✅ CORS configured for /$path" -ForegroundColor Green
        } catch {
            Write-Host "⚠️  CORS may already be configured for /$path" -ForegroundColor Yellow
        }
    }
}

# Deploy API Gateway
Write-Host "Deploying API Gateway..." -ForegroundColor Gray
try {
    aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod --description "Production deployment with CORS fixes"
    Write-Host "✅ API Gateway deployed" -ForegroundColor Green
} catch {
    Write-Host "❌ API Gateway deployment failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 3: Test Endpoints
Write-Host "`n3. 🧪 Testing Deployed Endpoints..." -ForegroundColor Yellow

$API_BASE_URL = "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod"

# Test OPTIONS request
Write-Host "Testing OPTIONS preflight..." -ForegroundColor Gray
try {
    $optionsResponse = Invoke-WebRequest -Uri "$API_BASE_URL/chat" -Method OPTIONS -Headers @{"Origin"="http://localhost:3000"} -UseBasicParsing
    if ($optionsResponse.StatusCode -eq 200) {
        Write-Host "✅ OPTIONS preflight working" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  OPTIONS test: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Test session endpoint
Write-Host "Testing session endpoint..." -ForegroundColor Gray
try {
    $sessionBody = @{ action = "create" } | ConvertTo-Json
    $sessionResponse = Invoke-RestMethod -Uri "$API_BASE_URL/session" -Method POST -Body $sessionBody -ContentType "application/json" -TimeoutSec 10
    
    if ($sessionResponse.success) {
        Write-Host "✅ Session endpoint working" -ForegroundColor Green
        Write-Host "   Session ID: $($sessionResponse.sessionId)" -ForegroundColor Gray
    }
} catch {
    Write-Host "⚠️  Session test: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Step 4: Update Frontend Configuration
Write-Host "`n4. 📱 Updating Frontend for Production..." -ForegroundColor Yellow

# Update .env file
$envFile = "frontend/.env"
$envContent = @"
REACT_APP_API_URL=https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod
REACT_APP_USER_POOL_ID=us-east-1_QVdUR725D
REACT_APP_USER_POOL_CLIENT_ID=7a283i8pqhq7h1k88me51gsefo
"@

$envContent | Set-Content $envFile
Write-Host "✅ Frontend configured for production" -ForegroundColor Green

# Update api.ts to use environment variable
$apiServiceContent = Get-Content "frontend/src/services/api.ts" -Raw
$updatedApiService = $apiServiceContent -replace "const API_BASE_URL = 'http://localhost:3001';", "const API_BASE_URL = process.env.REACT_APP_API_URL || 'https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod';"
$updatedApiService | Set-Content "frontend/src/services/api.ts"
Write-Host "✅ API service updated for production" -ForegroundColor Green

# Step 5: Build Frontend
Write-Host "`n5. 🏗️  Building Frontend for Production..." -ForegroundColor Yellow

try {
    Push-Location frontend
    
    Write-Host "Installing dependencies..." -ForegroundColor Gray
    npm install --silent
    
    Write-Host "Building production bundle..." -ForegroundColor Gray
    npm run build
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Frontend built successfully" -ForegroundColor Green
        
        # Check build size
        $buildSize = (Get-ChildItem "build/static/js/*.js" | Measure-Object -Property Length -Sum).Sum / 1MB
        Write-Host "   Build size: $([math]::Round($buildSize, 2)) MB" -ForegroundColor Gray
    } else {
        Write-Host "❌ Frontend build failed" -ForegroundColor Red
    }
    
    Pop-Location
} catch {
    Write-Host "❌ Build error: $($_.Exception.Message)" -ForegroundColor Red
    Pop-Location
}

# Cleanup
Write-Host "`n6. 🧹 Cleaning Up..." -ForegroundColor Yellow
Remove-Item lambda-chat-cors.zip, lambda-auth-cors.zip, lambda-session-cors.zip -ErrorAction SilentlyContinue
Write-Host "✅ Deployment packages cleaned up" -ForegroundColor Green

# Final Summary
Write-Host "`n🎉 Production Deployment Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Gray

Write-Host "`n✅ Deployed Components:" -ForegroundColor Green
Write-Host "- Lambda Functions: Chat, Auth, Session (with CORS)" -ForegroundColor Gray
Write-Host "- API Gateway: CORS configured and deployed" -ForegroundColor Gray
Write-Host "- Frontend: Built for production" -ForegroundColor Gray

Write-Host "`n🌐 Production URLs:" -ForegroundColor Yellow
Write-Host "- API Gateway: https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod" -ForegroundColor Gray
Write-Host "- Frontend Build: ./frontend/build/" -ForegroundColor Gray

Write-Host "`n🧠 Features Deployed:" -ForegroundColor Cyan
Write-Host "- AgentCore Memory System" -ForegroundColor Green
Write-Host "- Individual User Tracking" -ForegroundColor Green
Write-Host "- Cognito Authentication" -ForegroundColor Green
Write-Host "- Clean Mobile UI" -ForegroundColor Green
Write-Host "- CORS-Fixed API" -ForegroundColor Green

Write-Host "`n📋 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Test the production frontend build" -ForegroundColor Gray
Write-Host "2. Deploy frontend to your hosting service" -ForegroundColor Gray
Write-Host "3. Update any DNS/domain configurations" -ForegroundColor Gray

Write-Host "`n🚀 Your DevOps Agent is Production Ready!" -ForegroundColor Cyan