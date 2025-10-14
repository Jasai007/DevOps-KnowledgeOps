# Start frontend React application
Write-Host "🌐 Starting DevOps KnowledgeOps Frontend..." -ForegroundColor Green

# Check if frontend directory exists
if (-not (Test-Path "frontend")) {
    Write-Host "❌ Frontend directory not found!" -ForegroundColor Red
    exit 1
}

# Change to frontend directory
Set-Location frontend

# Check if node_modules exists
if (-not (Test-Path "node_modules")) {
    Write-Host "📦 Installing frontend dependencies..." -ForegroundColor Yellow
    npm install
}

Write-Host "🚀 Starting React development server..." -ForegroundColor Green
Write-Host "Frontend will be available at: http://localhost:3000" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Gray

# Start the frontend
npm start