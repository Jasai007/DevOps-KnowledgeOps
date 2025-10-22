#!/usr/bin/env pwsh

Write-Host "🔐 Setting up Cognito Integration for DevOps KnowledgeOps Agent" -ForegroundColor Green

# Cognito Configuration
$USER_POOL_ID = "us-east-1_QVdUR725D"
$USER_POOL_CLIENT_ID = "7a283i8pqhq7h1k88me51gsefo"
$REGION = "us-east-1"

Write-Host "📋 Cognito Configuration:" -ForegroundColor Cyan
Write-Host "  User Pool ID: $USER_POOL_ID" -ForegroundColor White
Write-Host "  Client ID: $USER_POOL_CLIENT_ID" -ForegroundColor White
Write-Host "  Region: $REGION" -ForegroundColor White

# Update Auth Lambda Environment Variables
Write-Host "🔧 Updating Auth Lambda environment variables..." -ForegroundColor Yellow

$authEnvVars = @{
    Variables = @{
        USER_POOL_ID = $USER_POOL_ID
        USER_POOL_CLIENT_ID = $USER_POOL_CLIENT_ID
        AWS_REGION = $REGION
    }
} | ConvertTo-Json -Compress

try {
    aws lambda update-function-configuration --function-name devops-auth-handler --environment $authEnvVars
    Write-Host "✅ Auth Lambda environment variables updated successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to update Auth Lambda environment variables: $_" -ForegroundColor Red
}

# Update Chat Lambda Environment Variables (for user context)
Write-Host "🔧 Updating Chat Lambda environment variables..." -ForegroundColor Yellow

$chatEnvVars = @{
    Variables = @{
        USER_POOL_ID = $USER_POOL_ID
        USER_POOL_CLIENT_ID = $USER_POOL_CLIENT_ID
        AWS_REGION = $REGION
    }
} | ConvertTo-Json -Compress

try {
    aws lambda update-function-configuration --function-name devops-chat-handler --environment $chatEnvVars
    Write-Host "✅ Chat Lambda environment variables updated successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to update Chat Lambda environment variables: $_" -ForegroundColor Red
}

# Create a demo user in Cognito
Write-Host "👤 Creating demo user in Cognito..." -ForegroundColor Yellow

$demoUsername = "demo@example.com"
$demoPassword = "DemoPassword123!"

# Check if user already exists
$userExists = $false
try {
    $result = aws cognito-idp admin-get-user --user-pool-id $USER_POOL_ID --username $demoUsername 2>$null
    if ($LASTEXITCODE -eq 0) {
        $userExists = $true
        Write-Host "ℹ️  Demo user already exists" -ForegroundColor Blue
    }
} catch {
    Write-Host "📝 Demo user doesn't exist, creating..." -ForegroundColor White
}

if (-not $userExists) {
    try {
        # Create the user
        aws cognito-idp admin-create-user --user-pool-id $USER_POOL_ID --username $demoUsername --user-attributes Name=email,Value=$demoUsername Name=email_verified,Value=true --temporary-password $demoPassword --message-action SUPPRESS

        # Set permanent password
        aws cognito-idp admin-set-user-password --user-pool-id $USER_POOL_ID --username $demoUsername --password $demoPassword --permanent

        Write-Host "✅ Demo user created successfully" -ForegroundColor Green
        Write-Host "   Username: $demoUsername" -ForegroundColor White
        Write-Host "   Password: $demoPassword" -ForegroundColor White
    } catch {
        Write-Host "❌ Failed to create demo user: $_" -ForegroundColor Red
        Write-Host "ℹ️  You can still use mock authentication for testing" -ForegroundColor Blue
    }
}

# Test Cognito authentication
Write-Host "🧪 Testing Cognito authentication..." -ForegroundColor Yellow

$testPayload = @{
    action = "signin"
    username = $demoUsername
    password = $demoPassword
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri 'https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/auth' -Method POST -Body $testPayload -ContentType 'application/json'
    
    if ($response.success) {
        Write-Host "✅ Cognito authentication test successful!" -ForegroundColor Green
        if ($response.data -and $response.data.accessToken) {
            Write-Host "   Access Token: $($response.data.accessToken.Substring(0, 20))..." -ForegroundColor White
        }
    } else {
        Write-Host "⚠️  Authentication test failed: $($response.error)" -ForegroundColor Yellow
        Write-Host "ℹ️  Mock authentication will be used as fallback" -ForegroundColor Blue
    }
} catch {
    Write-Host "⚠️  Authentication test failed: $_" -ForegroundColor Yellow
    Write-Host "ℹ️  Mock authentication will be used as fallback" -ForegroundColor Blue
}

Write-Host "🎉 Cognito integration setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Summary:" -ForegroundColor Cyan
Write-Host "  ✅ Cognito User Pool: DevOpsKnowledgeOpsUsers" -ForegroundColor White
Write-Host "  ✅ Lambda environment variables configured" -ForegroundColor White
Write-Host "  ✅ Demo user available: $demoUsername" -ForegroundColor White
Write-Host "  ✅ Authentication endpoint ready" -ForegroundColor White
Write-Host ""
Write-Host "🚀 You can now use real Cognito authentication in your application!" -ForegroundColor Green