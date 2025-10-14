# Fix ngrok PATH issue after winget installation
Write-Host "🔧 Fixing ngrok PATH issue..." -ForegroundColor Green

# Method 1: Refresh PATH environment variable
Write-Host "1. Refreshing PATH environment variable..." -ForegroundColor Yellow
$machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
$userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
$env:PATH = $machinePath + ";" + $userPath

# Test if ngrok is now available
Write-Host "2. Testing ngrok availability..." -ForegroundColor Yellow
try {
    $version = ngrok version
    Write-Host "✅ ngrok is now available: $version" -ForegroundColor Green
    
    # Configure auth token
    Write-Host "3. Configuring auth token..." -ForegroundColor Yellow
    ngrok config add-authtoken "3420TspFo0dAjnwKB6KcxvktQnc_6VunEreSjMyXAWJamYLh6"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Auth token configured successfully!" -ForegroundColor Green
        Write-Host "🚀 Ready to start tunnel with: ngrok http 5173" -ForegroundColor Cyan
    } else {
        Write-Host "⚠️ Auth token configuration may have failed" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "❌ ngrok still not found. Trying alternative methods..." -ForegroundColor Red
    
    # Method 2: Find ngrok manually
    Write-Host "4. Searching for ngrok installation..." -ForegroundColor Yellow
    
    $commonPaths = @(
        "$env:LOCALAPPDATA\Microsoft\WinGet\Links\ngrok.exe",
        "$env:PROGRAMFILES\ngrok\ngrok.exe",
        "$env:USERPROFILE\AppData\Local\Microsoft\WinGet\Links\ngrok.exe"
    )
    
    $found = $false
    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            Write-Host "✅ Found ngrok at: $path" -ForegroundColor Green
            
            # Test the executable
            try {
                $version = & $path version
                Write-Host "✅ ngrok version: $version" -ForegroundColor Green
                
                # Configure auth token using full path
                & $path config add-authtoken "3420TspFo0dAjnwKB6KcxvktQnc_6VunEreSjMyXAWJamYLh6"
                
                Write-Host "✅ Auth token configured!" -ForegroundColor Green
                Write-Host "Use this command to start tunnel:" -ForegroundColor Cyan
                Write-Host "   `"$path`" http 5173" -ForegroundColor White
                
                $found = $true
                break
            } catch {
                Write-Host "❌ Failed to run ngrok at $path" -ForegroundColor Red
            }
        }
    }
    
    if (-not $found) {
        Write-Host "❌ Could not find ngrok installation" -ForegroundColor Red
        Write-Host "Try these solutions:" -ForegroundColor Yellow
        Write-Host "   1. Restart PowerShell as Administrator" -ForegroundColor White
        Write-Host "   2. Run: winget uninstall ngrok.ngrok" -ForegroundColor White
        Write-Host "   3. Run: winget install ngrok.ngrok" -ForegroundColor White
        Write-Host "   4. Or download manually from: https://ngrok.com/download" -ForegroundColor White
    }
}