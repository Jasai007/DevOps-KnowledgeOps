# Fix signup issue by restarting everything properly
Write-Host "🔧 Fixing Signup Issue..." -ForegroundColor Green

# Step 1: Stop all processes
Write-Host "1. Stopping all Node processes..." -ForegroundColor Yellow
Get-Process node -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep 2

# Step 2: Load environment variables
Write-Host "2. Loading Cognito configuration..." -ForegroundColor Yellow
$env:USER_POOL_ID = "us-east-1_QVdUR725D"
$env:USER_POOL_CLIENT_ID = "7a283i8pqhq7h1k88me51gsefo"
$env:USER_POOL_CLIENT_SECRET = "vr0eledlg9ok3db66t3ktpmq7d0095o0a1moqv78ikjsv0mnp8m"
$env:AWS_REGION = "us-east-1"
$env:BEDROCK_AGENT_ID = "MNJESZYALW"

# Step 3: Start API server
Write-Host "3. Starting API server..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-Command", "cd backend; node server.js" -WindowStyle Minimized
Start-Sleep 3

# Step 4: Test API server
Write-Host "4. Testing API server..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "http://localhost:3001/health" -Method Get
    Write-Host "✅ API Server is running" -ForegroundColor Green
} catch {
    Write-Host "❌ API Server failed to start" -ForegroundColor Red
    exit 1
}

# Step 5: Test signup endpoint
Write-Host "5. Testing signup endpoint..." -ForegroundColor Yellow
try {
    $signupTest = @{
        action = "signup"
        username = "test-fix@example.com"
        email = "test-fix@example.com"
        password = "TestFix123!"
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri "http://localhost:3001/auth" -Method Post -Body $signupTest -ContentType "application/json"
    Write-Host "✅ Signup endpoint working: $($response.message)" -ForegroundColor Green
} catch {
    Write-Host "❌ Signup endpoint failed: $_" -ForegroundColor Red
}

Write-Host "`n🎉 Setup Complete!" -ForegroundColor Green
Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Start frontend: cd frontend && npm start" -ForegroundColor White
Write-Host "2. Go to http://localhost:3000" -ForegroundColor White
Write-Host "3. Click 'Create Account' and try signing up" -ForegroundColor White

Write-Host "`n💡 If signup still fails in frontend:" -ForegroundColor Yellow
Write-Host "- Check browser console for errors" -ForegroundColor White
Write-Host "- Make sure frontend is running on port 3000" -ForegroundColor White
Write-Host "- Verify API server is on port 3001" -ForegroundColor White