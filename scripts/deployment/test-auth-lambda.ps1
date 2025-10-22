# Test Auth Lambda Function Directly
Write-Host "🧪 Testing Auth Lambda Function Directly" -ForegroundColor Cyan

# Test with a simple payload to see if Lambda is working
Write-Host "Testing Lambda with simple payload..." -ForegroundColor Yellow

$testPayload = @{
    httpMethod = "POST"
    body = '{"action": "create-demo-user"}'
    headers = @{
        "Content-Type" = "application/json"
        "Origin" = "http://localhost:3000"
    }
} | ConvertTo-Json -Depth 3

# Invoke Lambda directly
try {
    Write-Host "Invoking Lambda function directly..." -ForegroundColor Gray
    $result = aws lambda invoke --function-name cors-auth-final --payload $testPayload --output json response.json
    
    if (Test-Path "response.json") {
        $response = Get-Content "response.json" | ConvertFrom-Json
        Write-Host "✅ Lambda Response:" -ForegroundColor Green
        $response | ConvertTo-Json
        Remove-Item "response.json"
    }
} catch {
    Write-Host "❌ Lambda invocation failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Check recent CloudWatch logs
Write-Host "`n📋 Checking recent CloudWatch logs..." -ForegroundColor Yellow
try {
    $logGroups = aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/cors-auth-final" --output json | ConvertFrom-Json
    if ($logGroups.logGroups.Count -gt 0) {
        $logGroupName = $logGroups.logGroups[0].logGroupName
        Write-Host "Log group: $logGroupName" -ForegroundColor Gray
        
        # Get recent log streams
        $logStreams = aws logs describe-log-streams --log-group-name $logGroupName --order-by LastEventTime --descending --max-items 1 --output json | ConvertFrom-Json
        if ($logStreams.logStreams.Count -gt 0) {
            $latestStream = $logStreams.logStreams[0].logStreamName
            Write-Host "Latest log stream: $latestStream" -ForegroundColor Gray
            
            # Get recent log events
            Write-Host "Recent log events:" -ForegroundColor Gray
            aws logs get-log-events --log-group-name $logGroupName --log-stream-name $latestStream --start-time $((Get-Date).AddMinutes(-10).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")) --output table
        }
    }
} catch {
    Write-Host "Could not retrieve logs: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n🎯 Lambda Test Complete" -ForegroundColor Cyan