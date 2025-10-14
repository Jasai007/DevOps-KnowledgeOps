# Restart backend server and test delete functionality
Write-Host "🔄 Restarting Backend Server..." -ForegroundColor Green

# Stop existing node processes
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

# Test the delete functionality
Write-Host "3. Testing delete functionality..." -ForegroundColor Yellow
node test-delete-sessions.js

Write-Host "`n✅ Test complete!" -ForegroundColor Green
Write-Host "Backend server is running in background (Job ID: $($serverJob.Id))" -ForegroundColor White