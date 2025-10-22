# DevOps KnowledgeOps Server Startup Script
Write-Host "🚀 Starting DevOps KnowledgeOps Server..." -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

# Check if Node.js is installed
try {
    $nodeVersion = node --version
    Write-Host "✅ Node.js version: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Node.js from https://nodejs.org/" -ForegroundColor Yellow
    exit 1
}

# Check if backend directory exists
if (-not (Test-Path "backend/server.js")) {
    Write-Host "❌ Backend server file not found" -ForegroundColor Red
    Write-Host "Please make sure you're running this from the project root directory" -ForegroundColor Yellow
    exit 1
}

# Install dependencies if needed
if (-not (Test-Path "backend/node_modules")) {
    Write-Host "📦 Installing backend dependencies..." -ForegroundColor Yellow
    Set-Location backend
    npm install
    Set-Location ..
}

Write-Host "🔧 Server Configuration:" -ForegroundColor Yellow
Write-Host "   - Port: 3001" -ForegroundColor Gray
Write-Host "   - Region: us-east-1" -ForegroundColor Gray
Write-Host "   - User Isolation: ENABLED" -ForegroundColor Gray
Write-Host "   - JWT Token Parsing: ENHANCED" -ForegroundColor Gray
Write-Host "   - Session Management: SECURE" -ForegroundColor Gray

Write-Host "`n🌐 Starting server on http://localhost:3001..." -ForegroundColor Green
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Gray
Write-Host ""

# Start the server
try {
    Set-Location backend
    node server.js
} catch {
    Write-Host "❌ Failed to start server: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    Set-Location ..
}