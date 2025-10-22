# DevOps KnowledgeOps Agent - Startup Script
Write-Host "🚀 Starting DevOps KnowledgeOps AI Assistant..." -ForegroundColor Green
Write-Host ""

# Set environment variables
$env:AWS_REGION = "us-east-1"
$env:BEDROCK_AGENT_ID = "MNJESZYALW"
$env:NODE_ENV = "development"

Write-Host "📋 Configuration:" -ForegroundColor Yellow
Write-Host "   AWS_REGION: $env:AWS_REGION"
Write-Host "   BEDROCK_AGENT_ID: $env:BEDROCK_AGENT_ID"
Write-Host "   NODE_ENV: $env:NODE_ENV"
Write-Host ""

# Function to start backend
function Start-Backend {
    Write-Host "🔧 Starting Backend API Server..." -ForegroundColor Cyan
    Set-Location backend
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "node server.js" -WindowStyle Normal
    Set-Location ..
    Write-Host "✅ Backend started in new window" -ForegroundColor Green
}

# Function to start frontend
function Start-Frontend {
    Write-Host "🎨 Starting Frontend React App..." -ForegroundColor Cyan
    Set-Location frontend
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "npm start" -WindowStyle Normal
    Set-Location ..
    Write-Host "✅ Frontend started in new window" -ForegroundColor Green
}

# Start both services
Start-Backend
Start-Sleep -Seconds 3
Start-Frontend

Write-Host ""
Write-Host "🎉 DevOps KnowledgeOps Agent is starting up!" -ForegroundColor Green
Write-Host ""
Write-Host "📱 Frontend: http://localhost:3000" -ForegroundColor Yellow
Write-Host "🔧 Backend API: http://localhost:3001" -ForegroundColor Yellow
Write-Host "🏥 Health Check: http://localhost:3001/health" -ForegroundColor Yellow
Write-Host ""
Write-Host "🧪 To test conversation memory:" -ForegroundColor Cyan
Write-Host "   node test-conversation-memory.js" -ForegroundColor White
Write-Host ""
Write-Host "⏹️  To stop: Close the PowerShell windows or press Ctrl+C in each" -ForegroundColor Red
Write-Host ""
Write-Host "Happy DevOps-ing! 🚀" -ForegroundColor Green