# Start Local Development Environment
# This script helps you start local development with the Lambda API

Write-Host "🚀 Starting Local Development Environment..." -ForegroundColor Cyan
Write-Host "DevOps KnowledgeOps Agent - Frontend + Lambda API Integration" -ForegroundColor Gray

# Test API connectivity first
Write-Host "`n🧪 Testing API connectivity..." -ForegroundColor Yellow

try {
    $testResponse = Invoke-RestMethod -Uri "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/auth" -Method POST -ContentType "application/json" -Body '{"email":"demo@example.com","password":"DemoPassword123!"}'
    
    if ($testResponse.success) {
        Write-Host "✅ Lambda API is working!" -ForegroundColor Green
        Write-Host "   Authentication: Working" -ForegroundColor Gray
        Write-Host "   User: $($testResponse.data.user.email)" -ForegroundColor Gray
    } else {
        Write-Host "❌ API test failed: $($testResponse.error)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Cannot connect to Lambda API: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Please check your internet connection and try again." -ForegroundColor Yellow
    exit 1
}

# Check if frontend directory exists
if (-not (Test-Path "frontend")) {
    Write-Host "❌ Frontend directory not found!" -ForegroundColor Red
    Write-Host "   Please run this script from the project root directory." -ForegroundColor Yellow
    exit 1
}

# Check if node_modules exists
if (-not (Test-Path "frontend/node_modules")) {
    Write-Host "`n📦 Installing frontend dependencies..." -ForegroundColor Yellow
    Set-Location frontend
    npm install
    Set-Location ..
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ Dependencies installed successfully!" -ForegroundColor Green
}

# Display configuration
Write-Host "`n🔧 Development Configuration:" -ForegroundColor Cyan
Write-Host "   API URL: https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod" -ForegroundColor Gray
Write-Host "   Frontend: http://localhost:3000" -ForegroundColor Gray
Write-Host "   Test User: demo@example.com" -ForegroundColor Gray
Write-Host "   Password: DemoPassword123!" -ForegroundColor Gray

Write-Host "`n📋 Available Features:" -ForegroundColor Cyan
Write-Host "   ✅ User Authentication (email/password)" -ForegroundColor Green
Write-Host "   ✅ Session Management" -ForegroundColor Green
Write-Host "   ✅ Chat Functionality" -ForegroundColor Green
Write-Host "   ✅ Multi-User Support" -ForegroundColor Green
Write-Host "   ✅ Real-time API Integration" -ForegroundColor Green

Write-Host "`n🚀 Starting React Development Server..." -ForegroundColor Yellow
Write-Host "   The app will open in your browser at http://localhost:3000" -ForegroundColor Gray
Write-Host "   Use Ctrl+C to stop the development server" -ForegroundColor Gray

# Start the development server
Set-Location frontend
npm start