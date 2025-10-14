# DevOps KnowledgeOps AI Assistant Startup Script
param(
    [string]$Region = "us-east-1",
    [string]$AgentId = "MNJESZYALW"
)

Write-Host "🚀 Starting DevOps KnowledgeOps AI Assistant..." -ForegroundColor Green

# Set environment variables
$env:AWS_REGION = $Region
$env:BEDROCK_AGENT_ID = $AgentId
$env:PORT = "3001"

Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "AWS Region: $Region"
Write-Host "Bedrock Agent ID: $AgentId"
Write-Host "API Server Port: 3001"
Write-Host "Frontend Port: 3000"

# Function to start API server
function Start-ApiServer {
    Write-Host "`n🔧 Starting API Server..." -ForegroundColor Yellow
    Set-Location backend
    Start-Process -FilePath "node" -ArgumentList "server.js" -WindowStyle Normal
    Write-Host "✅ API Server started on http://localhost:3001" -ForegroundColor Green
}

# Function to start frontend
function Start-Frontend {
    Write-Host "`n🎨 Starting Frontend..." -ForegroundColor Yellow
    Set-Location "frontend"
    Start-Process -FilePath "npm" -ArgumentList "start" -WindowStyle Normal
    Set-Location ".."
    Write-Host "✅ Frontend will start on http://localhost:3000" -ForegroundColor Green
}

# Start both services
Start-ApiServer
Start-Sleep -Seconds 3
Start-Frontend

Write-Host "`n🎉 DevOps KnowledgeOps AI Assistant is starting up!" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green
Write-Host "🔗 API Server: http://localhost:3001" -ForegroundColor White
Write-Host "🌐 Frontend: http://localhost:3000" -ForegroundColor White
Write-Host "🤖 Bedrock Agent: $AgentId" -ForegroundColor White

Write-Host "`n💡 Usage:" -ForegroundColor Cyan
Write-Host "1. Wait for both services to fully start (about 30 seconds)"
Write-Host "2. Open http://localhost:3000 in your browser"
Write-Host "3. Start chatting with your DevOps AI Assistant!"

Write-Host "`n🛑 To stop the services:" -ForegroundColor Yellow
Write-Host "- Close the terminal windows or press Ctrl+C in each"

Write-Host "`n🚀 Your AI-powered DevOps Assistant is ready!" -ForegroundColor Green