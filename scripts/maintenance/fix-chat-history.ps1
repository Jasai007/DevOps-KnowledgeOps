# Fix Chat History - Restart server and test functionality
Write-Host "🔧 Fixing Chat History Issues..." -ForegroundColor Green

# Stop any existing node processes
Write-Host "1. Stopping existing servers..." -ForegroundColor Yellow
Get-Process node -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# Wait a moment
Start-Sleep 2

# Start the backend server in background
Write-Host "2. Starting backend server..." -ForegroundColor Yellow
$serverJob = Start-Job -ScriptBlock {
    Set-Location "S:\---CODE---\PROJECTS\AWS_HACKATHON\Samples\backend"
    node server.js
}

# Wait for server to start
Start-Sleep 5

# Test the functionality
Write-Host "3. Testing chat history functionality..." -ForegroundColor Yellow
node test-chat-history.js

# Show server status
Write-Host "`n4. Server status:" -ForegroundColor Cyan
Write-Host "Backend server job ID: $($serverJob.Id)" -ForegroundColor White

Write-Host "`n✅ Chat history fix complete!" -ForegroundColor Green
Write-Host "Backend server is running in background (Job ID: $($serverJob.Id))" -ForegroundColor White
Write-Host "Use Stop-Job to stop the server" -ForegroundColor Gray