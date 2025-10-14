# Start both backend and frontend for DevOps KnowledgeOps
Write-Host "🚀 Starting Complete DevOps KnowledgeOps Application..." -ForegroundColor Green

# Check if required directories exist
$requiredDirs = @("backend", "frontend")
foreach ($dir in $requiredDirs) {
    if (-not (Test-Path $dir)) {
        Write-Host "❌ Directory '$dir' not found!" -ForegroundColor Red
        exit 1
    }
}

Write-Host "📋 Starting services..." -ForegroundColor Cyan

# Start backend in background
Write-Host "1. Starting backend API server..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-File", "start-backend.ps1" -WindowStyle Minimized

# Wait for backend to start
Start-Sleep 3

# Test if backend is running
try {
    $response = Invoke-RestMethod -Uri "http://localhost:3001/health" -Method Get -TimeoutSec 5
    Write-Host "✅ Backend API server is running" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Backend may still be starting..." -ForegroundColor Yellow
}

# Start frontend
Write-Host "2. Starting frontend React app..." -ForegroundColor Yellow
Write-Host "Frontend will open in your browser automatically" -ForegroundColor Cyan
Write-Host ""
Write-Host "🎉 Application Starting!" -ForegroundColor Green
Write-Host "Backend: http://localhost:3001" -ForegroundColor White
Write-Host "Frontend: http://localhost:3000" -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C to stop this script (backend will continue running)" -ForegroundColor Gray

# Start frontend (this will block)
.\start-frontend.ps1