Write-Host "🔍 Checking deployed Lambda functions..." -ForegroundColor Green

Write-Host "📋 Listing Lambda functions:" -ForegroundColor Yellow
aws lambda list-functions --query 'Functions[?contains(FunctionName, `devops`) || contains(FunctionName, `session`) || contains(FunctionName, `chat`)].{Name:FunctionName,Runtime:Runtime,LastModified:LastModified}' --output table

Write-Host ""
Write-Host "🔍 Checking API Gateway endpoints:" -ForegroundColor Yellow
aws apigateway get-rest-apis --query 'items[?contains(name, `devops`) || contains(name, `prod`)].{Name:name,Id:id,CreatedDate:createdDate}' --output table

Write-Host ""
Write-Host "🧪 Testing session endpoint directly:" -ForegroundColor Yellow
$testPayload = @{
    action = "create"
} | ConvertTo-Json

Write-Host "Test payload: $testPayload"

try {
    $response = Invoke-RestMethod -Uri "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/session" -Method POST -Body $testPayload -ContentType "application/json"
    Write-Host "✅ Session endpoint working!" -ForegroundColor Green
    Write-Host "Response: $($response | ConvertTo-Json)"
} catch {
    Write-Host "❌ Session endpoint error:" -ForegroundColor Red
    Write-Host $_.Exception.Message
    Write-Host "Status:" $_.Exception.Response.StatusCode
}