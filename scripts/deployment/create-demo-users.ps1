# Create Demo Users in Cognito User Pool
# This script creates demo users for testing the Lambda API

$USER_POOL_ID = "us-east-1_QVdUR725D"

Write-Host "🔧 Creating Demo Users in Cognito User Pool..." -ForegroundColor Cyan
Write-Host "User Pool ID: $USER_POOL_ID" -ForegroundColor Gray

# Demo users to create
$demoUsers = @(
    @{
        username = "demo@example.com"
        email = "demo@example.com"
        password = "TempPassword123!"
        tempPassword = "TempPass123!"
    },
    @{
        username = "admin@example.com"
        email = "admin@example.com"
        password = "AdminPassword123!"
        tempPassword = "AdminTemp123!"
    },
    @{
        username = "user@example.com"
        email = "user@example.com"
        password = "UserPassword123!"
        tempPassword = "UserTemp123!"
    }
)

foreach ($user in $demoUsers) {
    Write-Host "`n👤 Creating user: $($user.username)" -ForegroundColor Yellow
    
    try {
        # Create user with temporary password
        Write-Host "   Creating user with temporary password..." -ForegroundColor Gray
        aws cognito-idp admin-create-user `
            --user-pool-id $USER_POOL_ID `
            --username $($user.username) `
            --user-attributes Name=email,Value=$($user.email) Name=email_verified,Value=true `
            --temporary-password $($user.tempPassword) `
            --message-action SUPPRESS `
            --no-cli-pager
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✅ User created successfully" -ForegroundColor Green
            
            # Set permanent password
            Write-Host "   Setting permanent password..." -ForegroundColor Gray
            aws cognito-idp admin-set-user-password `
                --user-pool-id $USER_POOL_ID `
                --username $($user.username) `
                --password $($user.password) `
                --permanent `
                --no-cli-pager
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "   ✅ Password set successfully" -ForegroundColor Green
            } else {
                Write-Host "   ❌ Failed to set password" -ForegroundColor Red
            }
        } else {
            Write-Host "   ❌ Failed to create user" -ForegroundColor Red
        }
    } catch {
        Write-Host "   ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n🧪 Testing Authentication..." -ForegroundColor Cyan

# Test authentication with the first demo user
$testUser = $demoUsers[0]
Write-Host "Testing login for: $($testUser.username)" -ForegroundColor Gray

try {
    $authResult = aws cognito-idp admin-initiate-auth `
        --user-pool-id $USER_POOL_ID `
        --client-id "7a283i8pqhq7h1k88me51gsefo" `
        --auth-flow ADMIN_NO_SRP_AUTH `
        --auth-parameters USERNAME=$($testUser.username),PASSWORD=$($testUser.password) `
        --no-cli-pager `
        --output json | ConvertFrom-Json
    
    if ($authResult.AuthenticationResult) {
        Write-Host "✅ Authentication successful!" -ForegroundColor Green
        Write-Host "   Access Token: $($authResult.AuthenticationResult.AccessToken.Substring(0, 20))..." -ForegroundColor Gray
    } else {
        Write-Host "❌ Authentication failed" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Authentication test failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n📋 Demo Users Created:" -ForegroundColor Cyan
foreach ($user in $demoUsers) {
    Write-Host "   👤 $($user.username) / $($user.password)" -ForegroundColor Gray
}

Write-Host "`n🎯 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Test Lambda API with demo credentials" -ForegroundColor Gray
Write-Host "2. Verify frontend authentication works" -ForegroundColor Gray
Write-Host "3. Test session management and chat functionality" -ForegroundColor Gray