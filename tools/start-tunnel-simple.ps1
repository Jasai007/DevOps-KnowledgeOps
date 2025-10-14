# Simple tunnel setup without PATH dependencies
param(
    [int]$Port = 5173
)

Write-Host "🚀 Setting up tunnel for port $Port..." -ForegroundColor Green

# Try to find ngrok in common locations
$ngrokPaths = @(
    "ngrok.exe",  # If in PATH
    "$env:USERPROFILE\ngrok.exe",
    "$env:LOCALAPPDATA\ngrok\ngrok.exe",
    "$env:PROGRAMFILES\ngrok\ngrok.exe"
)

$ngrokFound = $false
foreach ($path in $ngrokPaths) {
    if (Get-Command $path -ErrorAction SilentlyContinue) {
        Write-Host "✅ Found ngrok at: $path" -ForegroundColor Green
        $ngrokPath = $path
        $ngrokFound = $true
        break
    }
}

if (-not $ngrokFound) {
    Write-Host "❌ ngrok not found. Please:" -ForegroundColor Red
    Write-Host "1. Download ngrok from: https://ngrok.com/download" -ForegroundColor Yellow
    Write-Host "2. Extract ngrok.exe to this folder" -ForegroundColor Yellow
    Write-Host "3. Run this script again" -ForegroundColor Yellow
    exit 1
}

# Configure auth token
Write-Host "Configuring auth token..." -ForegroundColor Cyan
$authToken = "3420TspFo0dAjnwKB6KcxvktQnc_6VunEreSjMyXAWJamYLh6"

try {
    & $ngrokPath config add-authtoken $authToken
    Write-Host "✅ Auth token configured!" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Auth token configuration may have failed, but continuing..." -ForegroundColor Yellow
}

# Start tunnel
Write-Host "Starting tunnel on port $Port..." -ForegroundColor Green
Write-Host "Press Ctrl+C to stop the tunnel" -ForegroundColor Gray
Write-Host ""

& $ngrokPath http $Port