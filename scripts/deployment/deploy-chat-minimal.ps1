Write-Host "Deploying minimal chat Lambda..." -ForegroundColor Green

Set-Location lambda/chat

Write-Host "Creating minimal deployment package..." -ForegroundColor Yellow
Compress-Archive -Path "chat-handler.js", "agentcore-gateway.js" -DestinationPath "chat-minimal.zip" -Force

Write-Host "Deploying to Lambda..." -ForegroundColor Yellow
aws lambda update-function-code --function-name agentcore-simple-chat --zip-file fileb://chat-minimal.zip

Remove-Item "chat-minimal.zip" -Force

Write-Host "Waiting for deployment..." -ForegroundColor Yellow
Start-Sleep -Seconds 8

Write-Host "Testing chat endpoint..." -ForegroundColor Yellow
Set-Location ..\..\

$testPayload = '{"message":"Hello, help me with DevOps","sessionId":"test-123"}'

try {
    $response = Invoke-RestMethod -Uri "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/chat" -Method POST -Body $testPayload -ContentType "application/json"
    Write-Host "SUCCESS!" -ForegroundColor Green
    Write-Host "Response length:" $response.response.Length
} catch {
    Write-Host "Error:" $_.Exception.Message -ForegroundColor Red
    
    # Try to get more details
    try {
        $errorResponse = $_.Exception.Response
        $reader = New-Object System.IO.StreamReader($errorResponse.GetResponseStream())
        $errorBody = $reader.ReadToEnd()
        Write-Host "Error details:" $errorBody -ForegroundColor Yellow
    } catch {
        Write-Host "Could not get error details" -ForegroundColor Yellow
    }
}

Write-Host "Deployment complete!" -ForegroundColor Green