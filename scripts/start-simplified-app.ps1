# Start Complete Simplified DevOps KnowledgeOps Agent
Write-Host "🎯 Starting Simplified DevOps KnowledgeOps Agent" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Gray

# Check prerequisites
Write-Host "🔍 Checking prerequisites..." -ForegroundColor Yellow

# Check Node.js
try {
    $nodeVersion = node --version
    Write-Host "✅ Node.js: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js not found. Please install Node.js first." -ForegroundColor Red
    exit 1
}

# Check npm
try {
    $npmVersion = npm --version
    Write-Host "✅ npm: v$npmVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ npm not found." -ForegroundColor Red
    exit 1
}

# Check AWS CLI (optional)
try {
    $awsVersion = aws --version
    Write-Host "✅ AWS CLI: Available" -ForegroundColor Green
} catch {
    Write-Host "⚠️  AWS CLI not found (required for AgentCore)" -ForegroundColor Yellow
    Write-Host "   Please install AWS CLI and configure credentials" -ForegroundColor Yellow
}

Write-Host "`n🏗️ Simplified Architecture:" -ForegroundColor Cyan
Write-Host "   Frontend: React (http://localhost:3000)" -ForegroundColor Gray
Write-Host "   Backend: Node.js + AgentCore (http://localhost:3001)" -ForegroundColor Gray
Write-Host "   Memory: Individual user sessions (in-memory)" -ForegroundColor Gray
Write-Host "   AI: Amazon Bedrock AgentCore (MNJESZYALW)" -ForegroundColor Gray
Write-Host "   Auth: Simple session-based (demo mode)" -ForegroundColor Gray

# Install backend dependencies
Write-Host "`n📦 Setting up backend..." -ForegroundColor Yellow
Set-Location backend

if (!(Test-Path "node_modules")) {
    Write-Host "Installing backend dependencies..." -ForegroundColor Gray
    npm install
    Write-Host "✅ Backend dependencies installed" -ForegroundColor Green
} else {
    Write-Host "✅ Backend dependencies already installed" -ForegroundColor Green
}

# Install frontend dependencies
Write-Host "`n📦 Setting up frontend..." -ForegroundColor Yellow
Set-Location ../frontend

if (!(Test-Path "node_modules")) {
    Write-Host "Installing frontend dependencies..." -ForegroundColor Gray
    npm install
    Write-Host "✅ Frontend dependencies installed" -ForegroundColor Green
} else {
    Write-Host "✅ Frontend dependencies already installed" -ForegroundColor Green
}

Set-Location ..

Write-Host "`n🚀 Starting Application..." -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Gray

# Set environment variables for backend
$env:BEDROCK_AGENT_ID = "MNJESZYALW"
$env:BEDROCK_AGENT_ALIAS_ID = "TSTALIASID"
$env:AWS_REGION = "us-east-1"
$env:PORT = "3001"
$env:CORS_ORIGIN = "http://localhost:3000"

Write-Host "🎯 Starting Backend Server (Port 3001)..." -ForegroundColor Yellow

# Start backend in background
$backendJob = Start-Job -ScriptBlock {
    Set-Location $using:PWD/backend
    $env:BEDROCK_AGENT_ID = "MNJESZYALW"
    $env:BEDROCK_AGENT_ALIAS_ID = "TSTALIASID"
    $env:AWS_REGION = "us-east-1"
    $env:PORT = "3001"
    $env:CORS_ORIGIN = "http://localhost:3000"
    node server.js
}

# Wait for backend to start
Write-Host "⏳ Waiting for backend to start..." -ForegroundColor Gray
Start-Sleep -Seconds 5

# Test backend health
try {
    $healthCheck = Invoke-RestMethod -Uri "http://localhost:3001/api/health" -TimeoutSec 5
    Write-Host "✅ Backend server is running" -ForegroundColor Green
    Write-Host "   Status: $($healthCheck.status)" -ForegroundColor Gray
    Write-Host "   AgentCore ID: $($healthCheck.agentId)" -ForegroundColor Gray
    Write-Host "   Memory Enabled: $($healthCheck.features.userMemory)" -ForegroundColor Gray
    Write-Host "   Individual Sessions: $($healthCheck.features.individualSessions)" -ForegroundColor Gray
} catch {
    Write-Host "⚠️  Backend health check failed, but continuing..." -ForegroundColor Yellow
}

Write-Host "`n🎯 Starting Frontend (Port 3000)..." -ForegroundColor Yellow

# Start frontend
Set-Location frontend
Write-Host "📱 Opening browser to http://localhost:3000" -ForegroundColor Gray
Write-Host "" -ForegroundColor Gray
Write-Host "🎉 Simplified DevOps KnowledgeOps Agent is starting!" -ForegroundColor Cyan
Write-Host "" -ForegroundColor Gray
Write-Host "Key Features:" -ForegroundColor Yellow
Write-Host "✅ AgentCore DevOps expertise" -ForegroundColor Green
Write-Host "✅ Individual user memory" -ForegroundColor Green
Write-Host "✅ Session management" -ForegroundColor Green
Write-Host "✅ No Lambda complexity" -ForegroundColor Green
Write-Host "✅ Local development friendly" -ForegroundColor Green
Write-Host "" -ForegroundColor Gray
Write-Host "Endpoints:" -ForegroundColor Yellow
Write-Host "📊 Health: http://localhost:3001/api/health" -ForegroundColor Gray
Write-Host "💬 Chat: http://localhost:3001/api/chat" -ForegroundColor Gray
Write-Host "🔐 Auth: http://localhost:3001/api/auth" -ForegroundColor Gray
Write-Host "📝 Session: http://localhost:3001/api/session" -ForegroundColor Gray
Write-Host "💾 Memory: http://localhost:3001/api/memory/:userId" -ForegroundColor Gray
Write-Host "" -ForegroundColor Gray
Write-Host "Press Ctrl+C to stop both servers" -ForegroundColor Yellow
Write-Host "" -ForegroundColor Gray

# Start frontend (this will block)
npm start

# Cleanup when frontend stops
Write-Host "`n🛑 Stopping backend server..." -ForegroundColor Yellow
Stop-Job $backendJob
Remove-Job $backendJob
Write-Host "✅ Application stopped" -ForegroundColor Green