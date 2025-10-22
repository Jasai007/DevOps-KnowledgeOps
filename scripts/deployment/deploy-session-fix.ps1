Write-Host "🚀 Deploying session handler fix..." -ForegroundColor Green

# Navigate to session directory
Set-Location lambda/session

# Install dependencies if needed
if (-not (Test-Path "node_modules")) {
    Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
    npm install
}

# Create deployment package
Write-Host "📦 Creating deployment package..." -ForegroundColor Yellow
Compress-Archive -Path "session-handler.ts", "session-manager.ts", "package.json", "node_modules" -DestinationPath "session-handler.zip" -Force

# Deploy to AWS Lambda
Write-Host "☁️ Deploying to AWS Lambda..." -ForegroundColor Yellow
aws lambda update-function-code --function-name simple-session-handler --zip-file fileb://session-handler.zip

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Session handler updated successfully!" -ForegroundColor Green
    
    # Clean up zip file
    Remove-Item "session-handler.zip"
    
    # Test the updated function
    Write-Host "🧪 Testing updated session endpoint..." -ForegroundColor Yellow
    Set-Location ..\..\
    
    $testPayload = @{
        action = "create"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/session" -Method POST -Body $testPayload -ContentType "application/json"
        Write-Host "✅ Session endpoint test successful!" -ForegroundColor Green
        Write-Host "Response: $($response | ConvertTo-Json)"
    } catch {
        Write-Host "❌ Session endpoint test failed:" -ForegroundColor Red
        Write-Host $_.Exception.Message
    }
    
} else {
    Write-Host "❌ Session handler deployment failed!" -ForegroundColor Red
    Set-Location ..\..\
    exit 1
}

Write-Host "🎉 Session fix deployment complete!" -ForegroundColor Green