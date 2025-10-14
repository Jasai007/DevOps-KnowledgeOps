# Simple Cognito Setup for DevOps KnowledgeOps
param(
    [string]$Region = "us-east-1",
    [string]$PoolName = "DevOpsKnowledgeOpsUsers"
)

Write-Host "Setting up AWS Cognito for DevOps KnowledgeOps..." -ForegroundColor Green

# Set region
$env:AWS_REGION = $Region

Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "Region: $Region"
Write-Host "User Pool Name: $PoolName"

try {
    # Step 1: Create User Pool
    Write-Host "`n1. Creating Cognito User Pool..." -ForegroundColor Yellow
    
    $userPoolResponse = aws cognito-idp create-user-pool `
        --pool-name $PoolName `
        --policies '{\"PasswordPolicy\":{\"MinimumLength\":8,\"RequireUppercase\":false,\"RequireLowercase\":false,\"RequireNumbers\":false,\"RequireSymbols\":false}}' `
        --auto-verified-attributes email `
        --username-attributes email `
        --region $Region `
        --output json
    
    $userPool = $userPoolResponse | ConvertFrom-Json
    $userPoolId = $userPool.UserPool.Id
    
    Write-Host "User Pool created: $userPoolId" -ForegroundColor Green
    
    # Step 2: Create User Pool Client
    Write-Host "`n2. Creating User Pool Client..." -ForegroundColor Yellow
    
    $clientResponse = aws cognito-idp create-user-pool-client `
        --user-pool-id $userPoolId `
        --client-name "DevOpsKnowledgeOpsApp" `
        --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH ALLOW_USER_SRP_AUTH `
        --generate-secret `
        --region $Region `
        --output json
    
    $client = $clientResponse | ConvertFrom-Json
    $clientId = $client.UserPoolClient.ClientId
    $clientSecret = $client.UserPoolClient.ClientSecret
    
    Write-Host "User Pool Client created: $clientId" -ForegroundColor Green
    
    # Step 3: Create demo users
    Write-Host "`n3. Creating demo users..." -ForegroundColor Yellow
    
    $demoUsers = @(
        @{ username = "demo@example.com"; email = "demo@example.com"; password = "Demo123!" },
        @{ username = "admin@example.com"; email = "admin@example.com"; password = "Admin123!" },
        @{ username = "user1@example.com"; email = "user1@example.com"; password = "User123!" }
    )
    
    foreach ($user in $demoUsers) {
        try {
            # Create user
            aws cognito-idp admin-create-user `
                --user-pool-id $userPoolId `
                --username $user.username `
                --user-attributes Name=email,Value=$($user.email) Name=email_verified,Value=true `
                --temporary-password $($user.password) `
                --message-action SUPPRESS `
                --region $Region | Out-Null
            
            # Set permanent password
            aws cognito-idp admin-set-user-password `
                --user-pool-id $userPoolId `
                --username $user.username `
                --password $($user.password) `
                --permanent `
                --region $Region | Out-Null
            
            Write-Host "  Created user: $($user.username) / $($user.password)" -ForegroundColor Green
        }
        catch {
            Write-Host "  User $($user.username) may already exist" -ForegroundColor Yellow
        }
    }
    
    # Step 4: Create environment configuration
    Write-Host "`n4. Creating environment configuration..." -ForegroundColor Yellow
    
    $envContent = @"
# AWS Cognito Configuration
AWS_REGION=$Region
USER_POOL_ID=$userPoolId
USER_POOL_CLIENT_ID=$clientId
USER_POOL_CLIENT_SECRET=$clientSecret

# Bedrock Configuration
BEDROCK_AGENT_ID=MNJESZYALW
EMBEDDING_MODEL=amazon.titan-embed-text-v2:0
VECTOR_DIMENSIONS=1024
"@

    $envContent | Out-File -FilePath "cognito-config.env" -Encoding UTF8
    
    Write-Host "Configuration saved to cognito-config.env" -ForegroundColor Green
    
    # Step 5: Output summary
    Write-Host "`nCognito Setup Complete!" -ForegroundColor Green
    Write-Host "=========================" -ForegroundColor Green
    Write-Host "User Pool ID: $userPoolId" -ForegroundColor White
    Write-Host "Client ID: $clientId" -ForegroundColor White
    Write-Host "Region: $Region" -ForegroundColor White
    
    Write-Host "`nDemo Users Created:" -ForegroundColor Cyan
    foreach ($user in $demoUsers) {
        Write-Host "  Username: $($user.username) | Password: $($user.password)" -ForegroundColor White
    }
    
    Write-Host "`nNext Steps:" -ForegroundColor Cyan
    Write-Host "1. Load configuration: source cognito-config.env"
    Write-Host "2. Update API server with Cognito integration"
    Write-Host "3. Add login UI to frontend"
    Write-Host "4. Test user-specific chat histories"
    
    Write-Host "`nReady for user authentication!" -ForegroundColor Green
    
} catch {
    Write-Host "Setup failed: $_" -ForegroundColor Red
    Write-Host "`nMake sure you have AWS CLI configured with proper permissions" -ForegroundColor Yellow
}