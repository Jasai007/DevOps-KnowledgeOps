Write-Host "🔍 Checking Lambda functions and endpoints..." -ForegroundColor Green

Write-Host "📋 Lambda functions:" -ForegroundColor Yellow
aws lambda list-functions --query 'Functions[].FunctionName' --output table

Write-Host ""
Write-Host "🧪 Testing session endpoint:" -ForegroundColor Yellow

$headers = @{
    'Content-Type' = 'application/json'
}

$body = @{
    action = "create"
} | ConvertTo-Json

Write-Host "Making request to session endpoint..."

try {
    $response = Invoke-WebRequest -Uri "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/session" -Method POST -Body $body -Headers $headers
    Write-Host "✅ Success! Status:" $response.StatusCode
    Write-Host "Response:" $response.Content
} catch {
    Write-Host "❌ Failed! Error:" $_.Exception.Message
}