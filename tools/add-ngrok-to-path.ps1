# Add ngrok to PATH environment variable
Write-Host "Adding ngrok to PATH environment variable..." -ForegroundColor Green

# Common ngrok installation paths
$possiblePaths = @(
    "$env:LOCALAPPDATA\Microsoft\WinGet\Links",
    "$env:PROGRAMFILES\ngrok",
    "$env:LOCALAPPDATA\ngrok",
    "$env:USERPROFILE\AppData\Local\Microsoft\WinGet\Links"
)

$ngrokPath = $null
foreach ($path in $possiblePaths) {
    $ngrokExe = Join-Path $path "ngrok.exe"
    if (Test-Path $ngrokExe) {
        Write-Host "Found ngrok at: $path" -ForegroundColor Green
        $ngrokPath = $path
        break
    }
}

if ($ngrokPath) {
    # Get current user PATH
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    
    # Check if path is already in PATH
    if ($currentPath -notlike "*$ngrokPath*") {
        # Add to user PATH
        $newPath = $currentPath + ";" + $ngrokPath
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
        
        Write-Host "Successfully added ngrok to PATH!" -ForegroundColor Green
        Write-Host "Please restart PowerShell and try: ngrok version" -ForegroundColor Cyan
    } else {
        Write-Host "ngrok path already exists in PATH" -ForegroundColor Yellow
    }
} else {
    Write-Host "Could not find ngrok installation" -ForegroundColor Red
    Write-Host "Try downloading manually from: https://ngrok.com/download" -ForegroundColor Yellow
}