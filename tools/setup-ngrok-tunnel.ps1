# Setup ngrok tunnel for DevOps KnowledgeOps
param(
    [Parameter(Mandatory=$true)]
    [string]$AuthToken,
    [int]$Port = 5173
)

Write-Host "🚀 Setting up ngrok tunnel for DevOps KnowledgeOps..." -ForegroundColor Green

# Step 1: Configure auth token
Write-Host "1. Configuring ngrok auth token..." -ForegroundColor Yellow
try {
    ngrok config add-authtoken $AuthToken
    Write-Host "✅ Auth token configured successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to configure auth token: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Check if the port is in use
Write-Host "2. Checking if port $Port is available..." -ForegroundColor Yellow
$portCheck = netstat -an | findstr ":$Port"
if ($portCheck) {
    Write-Host "✅ Port $Port is in use - ready for tunneling" -ForegroundColor Green
} else {
    Write-Host "⚠️ Port $Port doesn't seem to be in use" -ForegroundColor Yellow
    Write-Host "Make sure your app is running on port $Port first" -ForegroundColor Cyan
    
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne 'y') {
        Write-Host "Exiting..." -ForegroundColor Red
        exit 1
    }
}

# Step 3: Start ngrok tunnel
Write-Host "3. Starting ngrok tunnel..." -ForegroundColor Yellow
Write-Host "This will create a public URL for your app on port $Port" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop the tunnel" -ForegroundColor Gray
Write-Host ""

ngrok http $Port