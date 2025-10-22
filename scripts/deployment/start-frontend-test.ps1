Write-Host "🚀 Starting frontend for login test..." -ForegroundColor Green

Set-Location frontend

Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
npm install

Write-Host "🌐 Starting development server..." -ForegroundColor Yellow
Write-Host "The frontend will be available at http://localhost:3000" -ForegroundColor Cyan
Write-Host "Try logging in with:" -ForegroundColor Yellow
Write-Host "  Email: demo@example.com" -ForegroundColor White
Write-Host "  Password: DemoPassword123!" -ForegroundColor White

npm start