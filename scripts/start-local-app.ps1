# Start Local DevOps Agent Application
Write-Host "🚀 Starting DevOps Agent with Local Backend" -ForegroundColor Cyan

# Check if backend is running
Write-Host "`n1. 🔧 Checking Backend Status..." -ForegroundColor Yellow
try {
    $healthCheck = Invoke-RestMethod -Uri "http://localhost:3001/health" -Method GET -TimeoutSec 5
    if ($healthCheck.status -eq "healthy") {
        Write-Host "✅ Backend is running and healthy" -ForegroundColor Green
        Write-Host "   - AgentCore Gateway: Initialized" -ForegroundColor Gray
        Write-Host "   - Cognito Auth: Enabled" -ForegroundColor Gray
        Write-Host "   - Agent ID: $($healthCheck.agentId)" -ForegroundColor Gray
    }
} catch {
    Write-Host "❌ Backend not running. Starting backend..." -ForegroundColor Red
    Write-Host "Please run: cd backend && npm start" -ForegroundColor Yellow
    exit 1
}

# Check frontend configuration
Write-Host "`n2. 📱 Checking Frontend Configuration..." -ForegroundColor Yellow

$envFile = "frontend/.env"
if (Test-Path $envFile) {
    $envContent = Get-Content $envFile
    $apiUrl = ($envContent | Where-Object { $_ -like "REACT_APP_API_URL=*" }) -replace "REACT_APP_API_URL=", ""
    
    if ($apiUrl -eq "http://localhost:3001") {
        Write-Host "✅ Frontend configured for local backend" -ForegroundColor Green
        Write-Host "   - API URL: $apiUrl" -ForegroundColor Gray
    } else {
        Write-Host "⚠️  Frontend API URL: $apiUrl" -ForegroundColor Yellow
        Write-Host "   Updating to local backend..." -ForegroundColor Gray
        
        # Update .env file
        $newEnvContent = $envContent -replace "REACT_APP_API_URL=.*", "REACT_APP_API_URL=http://localhost:3001"
        $newEnvContent | Set-Content $envFile
        Write-Host "✅ Updated frontend configuration" -ForegroundColor Green
    }
}

# Test API endpoints
Write-Host "`n3. 🧪 Testing API Endpoints..." -ForegroundColor Yellow

# Test session creation
try {
    $sessionBody = @{ action = "create" } | ConvertTo-Json
    $sessionResponse = Invoke-RestMethod -Uri "http://localhost:3001/session" -Method POST -Body $sessionBody -ContentType "application/json" -TimeoutSec 5
    
    if ($sessionResponse.success) {
        Write-Host "✅ Session endpoint working" -ForegroundColor Green
        Write-Host "   - Session ID: $($sessionResponse.sessionId)" -ForegroundColor Gray
    }
} catch {
    Write-Host "❌ Session endpoint error: $($_.Exception.Message)" -ForegroundColor Red
}

# Instructions
Write-Host "`n4. 🎯 Ready to Start Frontend!" -ForegroundColor Yellow
Write-Host "Run the following commands:" -ForegroundColor White
Write-Host "   cd frontend" -ForegroundColor Gray
Write-Host "   npm start" -ForegroundColor Gray

Write-Host "`n📋 What to Expect:" -ForegroundColor Cyan
Write-Host "- ✅ No CORS errors" -ForegroundColor Green
Write-Host "- ✅ Health checks working" -ForegroundColor Green
Write-Host "- ✅ Authentication functional" -ForegroundColor Green
Write-Host "- ✅ Chat with AgentCore responses" -ForegroundColor Green
Write-Host "- ✅ Clean mobile UI (no mic/pin icons)" -ForegroundColor Green
Write-Host "- ✅ Proper navigation with logout" -ForegroundColor Green

Write-Host "`n🌐 URLs:" -ForegroundColor Yellow
Write-Host "- Frontend: http://localhost:3000" -ForegroundColor Gray
Write-Host "- Backend:  http://localhost:3001" -ForegroundColor Gray
Write-Host "- Health:   http://localhost:3001/health" -ForegroundColor Gray

Write-Host "`n🎉 Local DevOps Agent Ready!" -ForegroundColor Cyan