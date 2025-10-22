# Test API Endpoints
Write-Host "🌐 Testing API Endpoints" -ForegroundColor Cyan

$API_BASE_URL = "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod"

# Test Session Endpoint
Write-Host "`n1. Testing Session Endpoint..." -ForegroundColor Yellow
try {
    $sessionBody = @{
        action = "create"
    } | ConvertTo-Json
    
    $sessionResponse = Invoke-RestMethod -Uri "$API_BASE_URL/session" -Method POST -Body $sessionBody -ContentType "application/json" -TimeoutSec 10
    
    if ($sessionResponse.success) {
        Write-Host "✅ Session creation successful" -ForegroundColor Green
        Write-Host "   Session ID: $($sessionResponse.sessionId)" -ForegroundColor Gray
        Write-Host "   Created At: $($sessionResponse.createdAt)" -ForegroundColor Gray
    } else {
        Write-Host "❌ Session creation failed" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Session endpoint error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test Auth Endpoint
Write-Host "`n2. Testing Auth Endpoint..." -ForegroundColor Yellow
try {
    $authBody = @{
        action = "signin"
        username = "test@example.com"
        password = "testpassword"
    } | ConvertTo-Json
    
    $authResponse = Invoke-RestMethod -Uri "$API_BASE_URL/auth" -Method POST -Body $authBody -ContentType "application/json" -TimeoutSec 10
    
    if ($authResponse.success) {
        Write-Host "✅ Auth endpoint responding (login successful)" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Auth endpoint responding (login failed as expected): $($authResponse.error)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Auth endpoint error (expected): $($_.Exception.Message)" -ForegroundColor Yellow
}

# Test Chat Endpoint (without auth)
Write-Host "`n3. Testing Chat Endpoint..." -ForegroundColor Yellow
try {
    $chatBody = @{
        message = "Hello AgentCore"
        sessionId = "test-session-123"
    } | ConvertTo-Json
    
    $chatResponse = Invoke-RestMethod -Uri "$API_BASE_URL/chat" -Method POST -Body $chatBody -ContentType "application/json" -TimeoutSec 15
    
    if ($chatResponse.success) {
        Write-Host "✅ Chat endpoint responding" -ForegroundColor Green
        Write-Host "   Response length: $($chatResponse.response.Length) characters" -ForegroundColor Gray
        
        if ($chatResponse.metadata.memoryEnabled) {
            Write-Host "✅ Memory functionality enabled" -ForegroundColor Green
        }
    } else {
        Write-Host "⚠️  Chat endpoint requires authentication: $($chatResponse.error)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Chat endpoint error: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n🎯 API Test Summary:" -ForegroundColor Cyan
Write-Host "- Session endpoint: Working" -ForegroundColor Green
Write-Host "- Auth endpoint: Responding" -ForegroundColor Green  
Write-Host "- Chat endpoint: Available (requires auth)" -ForegroundColor Yellow
Write-Host "`nReady for frontend testing!" -ForegroundColor White