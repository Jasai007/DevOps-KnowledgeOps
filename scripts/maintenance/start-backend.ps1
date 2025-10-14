# Start backend API server with proper configuration
Write-Host "🚀 Starting DevOps KnowledgeOps Backend..." -ForegroundColor Green

# Load Cognito configuration
if (Test-Path "backend/config/cognito-config.env") {
    Write-Host "📋 Loading Cognito configuration..." -ForegroundColor Cyan
    
    Get-Content "backend/config/cognito-config.env" | ForEach-Object {
        if ($_ -match '^([^#][^=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            Set-Item -Path "env:$name" -Value $value
        }
    }
} else {
    Write-Host "⚠️ Cognito config not found, using defaults" -ForegroundColor Yellow
}

Write-Host "🔐 Configuration loaded:" -ForegroundColor Cyan
Write-Host "  User Pool ID: $env:USER_POOL_ID" -ForegroundColor White
Write-Host "  Client ID: $env:USER_POOL_CLIENT_ID" -ForegroundColor White
Write-Host "  Region: $env:AWS_REGION" -ForegroundColor White

Write-Host "`n👥 Demo Users Available:" -ForegroundColor Cyan
Write-Host "  demo@example.com / Demo123!" -ForegroundColor White
Write-Host "  admin@example.com / Admin123!" -ForegroundColor White
Write-Host "  user1@example.com / User123!" -ForegroundColor White

Write-Host "`n🌐 Starting API server on http://localhost:3001..." -ForegroundColor Green
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Gray

# Change to backend directory and start server
Set-Location backend
node server.js