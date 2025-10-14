# Use localtunnel instead of ngrok
param(
    [int]$Port = 5173,
    [string]$Subdomain = ""
)

Write-Host "🌐 Starting localtunnel for port $Port..." -ForegroundColor Green

# Check if port is in use
$portCheck = netstat -an | findstr ":$Port"
if (-not $portCheck) {
    Write-Host "⚠️ Port $Port doesn't seem to be in use" -ForegroundColor Yellow
    Write-Host "Make sure your app is running first!" -ForegroundColor Cyan
    
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne 'y') {
        exit 1
    }
}

# Start localtunnel
Write-Host "Creating public tunnel..." -ForegroundColor Cyan
Write-Host "This will give you a public URL like: https://random-name.loca.lt" -ForegroundColor Gray
Write-Host "Press Ctrl+C to stop the tunnel" -ForegroundColor Gray
Write-Host ""

if ($Subdomain) {
    lt --port $Port --subdomain $Subdomain
} else {
    lt --port $Port
}