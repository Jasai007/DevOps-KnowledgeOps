Write-Host "🚀 Deploying simple session handler..." -ForegroundColor Green

# Navigate to session directory
Set-Location lambda/session

# Create package.json if it doesn't exist
if (-not (Test-Path "package.json")) {
    Write-Host "📦 Creating package.json..." -ForegroundColor Yellow
    @{
        name = "simple-session-handler"
        version = "1.0.0"
        main = "simple-session-handler.js"
        dependencies = @{
            "@types/aws-lambda" = "^8.10.130"
        }
    } | ConvertTo-Json | Out-File -FilePath "package.json" -Encoding UTF8
}

# Create deployment package with just the simple handler
Write-Host "📦 Creating deployment package..." -ForegroundColor Yellow
Compress-Archive -Path "simple-session-handler.ts", "package.json" -DestinationPath "simple-session.zip" -Force

# Deploy to AWS Lambda
Write-Host "☁️ Deploying to AWS Lambda..." -ForegroundColor Yellow
aws lambda update-function-code --function-name simple-session-handler --zip-file fileb://simple-session.zip

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Lambda deployed successfully!" -ForegroundColor Green
    
    # Update the handler entry point
    Write-Host "🔧 Updating handler configuration..." -ForegroundColor Yellow
    aws lambda update-function-configuration --function-name simple-session-handler --handler simple-session-handler.handler
    
    # Clean up
    Remove-Item "simple-session.zip" -Force
    
    # Test the function
    Write-Host "🧪 Testing Lambda function..." -ForegroundColor Yellow
    Set-Location ..\..\
    
    $testPayload = '{"action":"create"}'
    Write-Host "Test payload: $testPayload"
    
    try {
        $response = Invoke-RestMethod -Uri "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/session" -Method POST -Body $testPayload -ContentType "application/json"
        Write-Host "✅ Function test successful!" -ForegroundColor Green
        Write-Host "Response: $($response | ConvertTo-Json)"
    } catch {
        Write-Host "❌ Function test failed:" -ForegroundColor Red
        Write-Host $_.Exception.Message
    }
    
} else {
    Write-Host "❌ Lambda deployment failed!" -ForegroundColor Red
    Set-Location ..\..\
    exit 1
}

Write-Host "🎉 Simple session handler deployment complete!" -ForegroundColor Green