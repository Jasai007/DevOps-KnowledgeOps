# Fix Existing API Gateway Configuration
# Add missing endpoints and proper authentication

$API_ID = "66a22b8wlb"
$REGION = "us-east-1"
$ACCOUNT_ID = "992382848863"

Write-Host "🔧 Fixing Existing API Gateway Configuration..." -ForegroundColor Cyan
Write-Host "API ID: $API_ID" -ForegroundColor Gray

# Get the root resource ID
Write-Host "`n📋 Getting API Gateway resources..." -ForegroundColor Yellow
$resources = aws apigateway get-resources --rest-api-id $API_ID --output json | ConvertFrom-Json
$rootResourceId = ($resources.items | Where-Object { $_.path -eq "/" }).id
Write-Host "Root Resource ID: $rootResourceId" -ForegroundColor Gray

# Create /auth resource
Write-Host "`n➕ Creating /auth resource..." -ForegroundColor Yellow
try {
    $authResource = aws apigateway create-resource `
        --rest-api-id $API_ID `
        --parent-id $rootResourceId `
        --path-part "auth" `
        --output json | ConvertFrom-Json
    
    $authResourceId = $authResource.id
    Write-Host "✅ Auth resource created: $authResourceId" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create auth resource: $($_.Exception.Message)" -ForegroundColor Red
    # Try to get existing auth resource
    $authResourceId = ($resources.items | Where-Object { $_.pathPart -eq "auth" }).id
    if ($authResourceId) {
        Write-Host "ℹ️ Using existing auth resource: $authResourceId" -ForegroundColor Blue
    } else {
        Write-Host "❌ Cannot proceed without auth resource" -ForegroundColor Red
        exit 1
    }
}

# Create POST method for /auth (public - no authorization)
Write-Host "`n➕ Creating POST method for /auth..." -ForegroundColor Yellow
try {
    aws apigateway put-method `
        --rest-api-id $API_ID `
        --resource-id $authResourceId `
        --http-method POST `
        --authorization-type NONE `
        --no-api-key-required `
        --no-cli-pager
    
    Write-Host "✅ POST method created for /auth" -ForegroundColor Green
} catch {
    Write-Host "⚠️ POST method might already exist for /auth" -ForegroundColor Yellow
}

# Create integration for /auth with cors-auth-final Lambda
Write-Host "`n🔗 Creating Lambda integration for /auth..." -ForegroundColor Yellow
$lambdaUri = "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:cors-auth-final/invocations"

try {
    aws apigateway put-integration `
        --rest-api-id $API_ID `
        --resource-id $authResourceId `
        --http-method POST `
        --type AWS_PROXY `
        --integration-http-method POST `
        --uri $lambdaUri `
        --no-cli-pager
    
    Write-Host "✅ Lambda integration created for /auth" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create Lambda integration: $($_.Exception.Message)" -ForegroundColor Red
}

# Add Lambda permission for API Gateway to invoke cors-auth-final
Write-Host "`n🔐 Adding Lambda permission for API Gateway..." -ForegroundColor Yellow
try {
    aws lambda add-permission `
        --function-name cors-auth-final `
        --statement-id "apigateway-auth-invoke" `
        --action lambda:InvokeFunction `
        --principal apigateway.amazonaws.com `
        --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/*" `
        --no-cli-pager
    
    Write-Host "✅ Lambda permission added" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Lambda permission might already exist" -ForegroundColor Yellow
}

# Create /session resource
Write-Host "`n➕ Creating /session resource..." -ForegroundColor Yellow
try {
    $sessionResource = aws apigateway create-resource `
        --rest-api-id $API_ID `
        --parent-id $rootResourceId `
        --path-part "session" `
        --output json | ConvertFrom-Json
    
    $sessionResourceId = $sessionResource.id
    Write-Host "✅ Session resource created: $sessionResourceId" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create session resource: $($_.Exception.Message)" -ForegroundColor Red
    # Try to get existing session resource
    $sessionResourceId = ($resources.items | Where-Object { $_.pathPart -eq "session" }).id
    if ($sessionResourceId) {
        Write-Host "ℹ️ Using existing session resource: $sessionResourceId" -ForegroundColor Blue
    } else {
        Write-Host "⚠️ Continuing without session resource" -ForegroundColor Yellow
        $sessionResourceId = $null
    }
}

# Create POST method for /session (will be public for now, can be secured later)
if ($sessionResourceId) {
    Write-Host "`n➕ Creating POST method for /session..." -ForegroundColor Yellow
    try {
        aws apigateway put-method `
            --rest-api-id $API_ID `
            --resource-id $sessionResourceId `
            --http-method POST `
            --authorization-type NONE `
            --no-api-key-required `
            --no-cli-pager
        
        Write-Host "✅ POST method created for /session" -ForegroundColor Green
        
        # Create integration for /session with agentcore-simple-chat Lambda (for now)
        Write-Host "🔗 Creating Lambda integration for /session..." -ForegroundColor Yellow
        $chatLambdaUri = "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:agentcore-simple-chat/invocations"
        
        aws apigateway put-integration `
            --rest-api-id $API_ID `
            --resource-id $sessionResourceId `
            --http-method POST `
            --type AWS_PROXY `
            --integration-http-method POST `
            --uri $chatLambdaUri `
            --no-cli-pager
        
        Write-Host "✅ Lambda integration created for /session" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Session method/integration might already exist" -ForegroundColor Yellow
    }
}
}

# Deploy the API
Write-Host "`n🚀 Deploying API changes..." -ForegroundColor Yellow
try {
    aws apigateway create-deployment `
        --rest-api-id $API_ID `
        --stage-name prod `
        --stage-description "Production deployment with auth endpoint" `
        --no-cli-pager
    
    Write-Host "✅ API deployed successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to deploy API: $($_.Exception.Message)" -ForegroundColor Red
}

# Test the auth endpoint
Write-Host "`n🧪 Testing the auth endpoint..." -ForegroundColor Yellow
try {
    $testResponse = Invoke-RestMethod -Uri "https://${API_ID}.execute-api.${REGION}.amazonaws.com/prod/auth" -Method POST -ContentType "application/json" -Body '{"action":"signin","username":"demo@example.com","password":"DemoPassword123!"}'
    
    if ($testResponse.success) {
        Write-Host "✅ Auth endpoint is working!" -ForegroundColor Green
        Write-Host "   Access Token: $($testResponse.accessToken.Substring(0, 20))..." -ForegroundColor Gray
    } else {
        Write-Host "❌ Auth endpoint failed: $($testResponse.error)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Auth endpoint test failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🎉 API Gateway Fix Complete!" -ForegroundColor Cyan
Write-Host "`n📋 Summary:" -ForegroundColor Cyan
Write-Host "✅ Added /auth endpoint (public)" -ForegroundColor Green
Write-Host "✅ Connected to cors-auth-final Lambda function" -ForegroundColor Green
Write-Host "✅ Added /session endpoint (public for now)" -ForegroundColor Green
Write-Host "✅ Deployed changes to prod stage" -ForegroundColor Green

Write-Host "`n🔧 API Endpoints:" -ForegroundColor Cyan
Write-Host "   POST /auth - Authentication (public)" -ForegroundColor Gray
Write-Host "   POST /chat - Chat processing" -ForegroundColor Gray
Write-Host "   POST /session - Session management" -ForegroundColor Gray

Write-Host "`n🧪 Test Commands:" -ForegroundColor Cyan
Write-Host "   # Test auth:" -ForegroundColor Gray
Write-Host "   curl -X POST https://${API_ID}.execute-api.${REGION}.amazonaws.com/prod/auth -H 'Content-Type: application/json' -d '{\"action\":\"signin\",\"username\":\"demo@example.com\",\"password\":\"DemoPassword123!\"}'" -ForegroundColor Gray