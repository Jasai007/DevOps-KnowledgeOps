# Start Simplified AgentCore Backend Server
Write-Host "🚀 Starting DevOps KnowledgeOps Agent - Simplified AgentCore Backend" -ForegroundColor Cyan

# Check if Node.js is installed
try {
    $nodeVersion = node --version
    Write-Host "✅ Node.js version: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js not found. Please install Node.js first." -ForegroundColor Red
    exit 1
}

# Set environment variables for AgentCore
$env:BEDROCK_AGENT_ID = "MNJESZYALW"
$env:BEDROCK_AGENT_ALIAS_ID = "TSTALIASID"
$env:AWS_REGION = "us-east-1"
$env:PORT = "3001"
$env:CORS_ORIGIN = "http://localhost:3000"

Write-Host "🔧 AgentCore Configuration:" -ForegroundColor Yellow
Write-Host "   Agent ID: $env:BEDROCK_AGENT_ID" -ForegroundColor Gray
Write-Host "   Alias ID: $env:BEDROCK_AGENT_ALIAS_ID" -ForegroundColor Gray
Write-Host "   AWS Region: $env:AWS_REGION" -ForegroundColor Gray
Write-Host "   Server Port: $env:PORT" -ForegroundColor Gray
Write-Host "   CORS Origin: $env:CORS_ORIGIN" -ForegroundColor Gray

# Navigate to backend directory
Set-Location backend

# Install dependencies if needed
if (!(Test-Path "node_modules")) {
    Write-Host "📦 Installing backend dependencies..." -ForegroundColor Yellow
    npm install
}

# Start the simplified server
Write-Host "🚀 Starting AgentCore Backend Server..." -ForegroundColor Cyan
Write-Host "📊 Health check: http://localhost:3001/api/health" -ForegroundColor Gray
Write-Host "💬 Chat endpoint: http://localhost:3001/api/chat" -ForegroundColor Gray
Write-Host "🔐 Auth endpoint: http://localhost:3001/api/auth" -ForegroundColor Gray
Write-Host "📝 Session endpoint: http://localhost:3001/api/session" -ForegroundColor Gray
Write-Host "💾 Memory endpoint: http://localhost:3001/api/memory/:userId" -ForegroundColor Gray
Write-Host "" -ForegroundColor Gray
Write-Host "Features:" -ForegroundColor Yellow
Write-Host "✅ AgentCore direct integration" -ForegroundColor Green
Write-Host "✅ Individual user memory" -ForegroundColor Green
Write-Host "✅ Session-based authentication" -ForegroundColor Green
Write-Host "✅ CORS-enabled local backend" -ForegroundColor Green
Write-Host "✅ No Lambda complexity" -ForegroundColor Green
Write-Host "" -ForegroundColor Gray
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host "" -ForegroundColor Gray

# Start the server
node server.js