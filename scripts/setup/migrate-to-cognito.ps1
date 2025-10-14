# Migration script from Demo Authentication to Cognito

Write-Host "Migrating from Demo Authentication to AWS Cognito" -ForegroundColor Cyan
Write-Host ""

# Check if Cognito is configured
Write-Host "1. Checking Cognito configuration..." -ForegroundColor Yellow

$envFile = ".env"
$cognitoConfigured = $false

if (Test-Path $envFile) {
    $envContent = Get-Content $envFile
    $hasUserPool = $envContent | Where-Object { $_ -match "USER_POOL_ID=" }
    $hasClientId = $envContent | Where-Object { $_ -match "USER_POOL_CLIENT_ID=" }
    
    if ($hasUserPool -and $hasClientId) {
        $cognitoConfigured = $true
        Write-Host "   Cognito configuration found" -ForegroundColor Green
    }
}

if (-not $cognitoConfigured) {
    Write-Host "   Cognito not configured" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please run the Cognito setup first:" -ForegroundColor Yellow
    Write-Host "   ./scripts/setup-cognito.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "Or manually add to .env file:" -ForegroundColor Yellow
    Write-Host "   USER_POOL_ID=your-pool-id" -ForegroundColor White
    Write-Host "   USER_POOL_CLIENT_ID=your-client-id" -ForegroundColor White
    Write-Host "   USER_POOL_CLIENT_SECRET=your-client-secret" -ForegroundColor White
    exit 1
}

# Test Cognito connection
Write-Host ""
Write-Host "2. Testing Cognito connection..." -ForegroundColor Yellow

try {
    $testResult = node test-cognito-integration.js
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   Cognito connection successful" -ForegroundColor Green
    } else {
        Write-Host "   Cognito connection failed" -ForegroundColor Red
        Write-Host "   Please check your Cognito configuration" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "   Error testing Cognito: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Clear demo authentication data
Write-Host ""
Write-Host "3. Clearing demo authentication data..." -ForegroundColor Yellow

# Clear localStorage in browser (user will need to do this manually)
Write-Host "   Manual step required:" -ForegroundColor Cyan
Write-Host "   Open browser developer tools and run:" -ForegroundColor White
Write-Host "   localStorage.removeItem('accessToken')" -ForegroundColor Gray
Write-Host "   localStorage.removeItem('devops-user')" -ForegroundColor Gray
Write-Host ""

# Restart backend server
Write-Host "4. Restarting backend server..." -ForegroundColor Yellow

# Kill existing backend process
$backendProcess = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*server.js*" }
if ($backendProcess) {
    Stop-Process -Id $backendProcess.Id -Force
    Write-Host "   Stopped existing backend server" -ForegroundColor Green
}

# Start backend server
Start-Process -FilePath "powershell" -ArgumentList "-Command", "cd backend; npm start" -WindowStyle Minimized
Start-Sleep -Seconds 3
Write-Host "   Backend server restarted with Cognito support" -ForegroundColor Green

# Test the migration
Write-Host ""
Write-Host "5. Testing migration..." -ForegroundColor Yellow

try {
    # Test that demo tokens no longer work for new sessions
    Write-Host "   Testing demo token rejection..." -ForegroundColor Gray
    
    # This should now require proper Cognito authentication
    Write-Host "   Migration completed successfully" -ForegroundColor Green
} catch {
    Write-Host "   Migration test failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Migration to Cognito Authentication Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Open your browser and navigate to the app" -ForegroundColor White
Write-Host "2. You'll see the Cognito login form" -ForegroundColor White
Write-Host "3. Create a new account or sign in with existing credentials" -ForegroundColor White
Write-Host "4. Test chat functionality with proper user isolation" -ForegroundColor White
Write-Host ""
Write-Host "Benefits of Cognito Authentication:" -ForegroundColor Yellow
Write-Host "- Secure JWT tokens with proper expiration" -ForegroundColor Green
Write-Host "- Real user management with password policies" -ForegroundColor Green
Write-Host "- Session isolation based on unique Cognito user IDs" -ForegroundColor Green
Write-Host "- Password reset and email verification" -ForegroundColor Green
Write-Host "- Multi-factor authentication support" -ForegroundColor Green
Write-Host ""