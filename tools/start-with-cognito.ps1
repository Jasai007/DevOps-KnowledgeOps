# Start API server with Cognito configuration
param(
    [switch]$Test = $false
)

Write-Host "Starting DevOps KnowledgeOps with Cognito Authentication..." -ForegroundColor Green

# Load Cognito configuration
if (Test-Path "cognito-config.env") {
    Write-Host "Loading Cognito configuration..." -ForegroundColor Cyan
    
    Get-Content "cognito-config.env" | ForEach-Object {
        if ($_ -match '^([^#][^=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            Set-Item -Path "env:$name" -Value $value
            Write-Host "  $name = $value" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "cognito-config.env not found, using defaults" -ForegroundColor Yellow
}

Write-Host "`nCognito Configuration:" -ForegroundColor Cyan
Write-Host "  User Pool ID: $env:USER_POOL_ID" -ForegroundColor White
Write-Host "  Client ID: $env:USER_POOL_CLIENT_ID" -ForegroundColor White
Write-Host "  Region: $env:AWS_REGION" -ForegroundColor White

Write-Host "`nDemo Users Available:" -ForegroundColor Cyan
Write-Host "  demo@example.com / Demo123!" -ForegroundColor White
Write-Host "  admin@example.com / Admin123!" -ForegroundColor White
Write-Host "  user1@example.com / User123!" -ForegroundColor White

if ($Test) {
    Write-Host "`nRunning authentication tests..." -ForegroundColor Yellow
    node test-cognito-auth.js
} else {
    Write-Host "`nStarting API server on http://localhost:3001..." -ForegroundColor Green
    Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Gray
    Set-Location backend
    node server.js
}