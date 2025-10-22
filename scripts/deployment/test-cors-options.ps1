Write-Host "🧪 Testing CORS OPTIONS request..." -ForegroundColor Green

Write-Host "Testing OPTIONS request to session endpoint..." -ForegroundColor Yellow

try {
    $response = Invoke-WebRequest -Uri "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/session" -Method OPTIONS -Headers @{
        'Access-Control-Request-Method' = 'POST'
        'Access-Control-Request-Headers' = 'Content-Type'
        'Origin' = 'http://localhost:3000'
    }
    
    Write-Host "✅ OPTIONS request successful!" -ForegroundColor Green
    Write-Host "Status Code:" $response.StatusCode
    Write-Host "Headers:" -ForegroundColor Yellow
    $response.Headers | Format-Table
    
} catch {
    Write-Host "❌ OPTIONS request failed!" -ForegroundColor Red
    Write-Host "Error:" $_.Exception.Message
    Write-Host "Status Code:" $_.Exception.Response.StatusCode
    Write-Host "Response:" $_.Exception.Response
}

Write-Host ""
Write-Host "🧪 Testing auth endpoint OPTIONS for comparison..." -ForegroundColor Yellow

try {
    $authResponse = Invoke-WebRequest -Uri "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/auth" -Method OPTIONS -Headers @{
        'Access-Control-Request-Method' = 'POST'
        'Access-Control-Request-Headers' = 'Content-Type'
        'Origin' = 'http://localhost:3000'
    }
    
    Write-Host "✅ Auth OPTIONS successful!" -ForegroundColor Green
    Write-Host "Status Code:" $authResponse.StatusCode
    Write-Host "Headers:" -ForegroundColor Yellow
    $authResponse.Headers | Format-Table
    
} catch {
    Write-Host "❌ Auth OPTIONS failed!" -ForegroundColor Red
    Write-Host "Error:" $_.Exception.Message
}