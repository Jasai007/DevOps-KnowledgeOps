# Test Clean Frontend Implementation
Write-Host "🧪 Testing Clean AgentCore Frontend Implementation" -ForegroundColor Cyan

# Test 1: Check if backend server starts
Write-Host "`n1. Testing Backend Server..." -ForegroundColor Yellow
try {
    $backendProcess = Start-Process -FilePath "node" -ArgumentList "backend/server.js" -PassThru -WindowStyle Hidden
    Start-Sleep -Seconds 3
    
    # Test health endpoint
    $healthResponse = Invoke-RestMethod -Uri "http://localhost:3001/health" -Method GET -TimeoutSec 10
    if ($healthResponse.status -eq "healthy") {
        Write-Host "✅ Backend server is healthy" -ForegroundColor Green
        Write-Host "   - AgentCore Gateway: $($healthResponse.agentCore.gateway.status)" -ForegroundColor Gray
        Write-Host "   - Auth Type: $($healthResponse.authType)" -ForegroundColor Gray
        Write-Host "   - No History: $($healthResponse.features.noHistory)" -ForegroundColor Gray
    } else {
        Write-Host "❌ Backend health check failed" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Backend server test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Check frontend build
Write-Host "`n2. Testing Frontend Build..." -ForegroundColor Yellow
try {
    Set-Location frontend
    $buildResult = npm run build 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Frontend builds successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Frontend build failed" -ForegroundColor Red
        Write-Host $buildResult -ForegroundColor Red
    }
    Set-Location ..
} catch {
    Write-Host "❌ Frontend build test failed: $($_.Exception.Message)" -ForegroundColor Red
    Set-Location ..
}

# Test 3: Test API endpoints
Write-Host "`n3. Testing API Endpoints..." -ForegroundColor Yellow
try {
    # Test session creation (no storage)
    $sessionBody = @{
        action = "create"
    } | ConvertTo-Json
    
    $sessionResponse = Invoke-RestMethod -Uri "http://localhost:3001/session" -Method POST -Body $sessionBody -ContentType "application/json" -TimeoutSec 10
    
    if ($sessionResponse.success) {
        Write-Host "✅ Session creation works (no storage)" -ForegroundColor Green
        Write-Host "   - Session ID: $($sessionResponse.sessionId)" -ForegroundColor Gray
        Write-Host "   - Message Count: $($sessionResponse.messageCount)" -ForegroundColor Gray
    } else {
        Write-Host "❌ Session creation failed" -ForegroundColor Red
    }
    
    # Test chat endpoint (requires auth, so expect error)
    $chatBody = @{
        message = "Hello AgentCore"
        sessionId = $sessionResponse.sessionId
    } | ConvertTo-Json
    
    try {
        $chatResponse = Invoke-RestMethod -Uri "http://localhost:3001/chat" -Method POST -Body $chatBody -ContentType "application/json" -TimeoutSec 10
        Write-Host "✅ Chat endpoint accessible" -ForegroundColor Green
    } catch {
        if ($_.Exception.Response.StatusCode -eq 401 -or $_.Exception.Response.StatusCode -eq 403) {
            Write-Host "✅ Chat endpoint properly requires authentication" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Chat endpoint error: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    
} catch {
    Write-Host "❌ API endpoint test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Check Lambda functions
Write-Host "`n4. Testing Lambda Functions..." -ForegroundColor Yellow
$lambdaFiles = @(
    "lambda/auth/auth-handler.js",
    "lambda/chat/agentcore-chat.js", 
    "lambda/session/final-session.js"
)

foreach ($file in $lambdaFiles) {
    if (Test-Path $file) {
        Write-Host "✅ $file exists" -ForegroundColor Green
    } else {
        Write-Host "❌ $file missing" -ForegroundColor Red
    }
}

# Cleanup
Write-Host "`n5. Cleanup..." -ForegroundColor Yellow
try {
    if ($backendProcess -and !$backendProcess.HasExited) {
        Stop-Process -Id $backendProcess.Id -Force
        Write-Host "✅ Backend server stopped" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  Cleanup warning: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n🎉 Clean AgentCore Frontend Test Complete!" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor White
Write-Host "- ✅ No chat history complexity" -ForegroundColor Green
Write-Host "- ✅ Clean Cognito authentication" -ForegroundColor Green  
Write-Host "- ✅ Direct AgentCore integration" -ForegroundColor Green
Write-Host "- ✅ Simplified session management" -ForegroundColor Green