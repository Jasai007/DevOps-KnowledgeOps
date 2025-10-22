Write-Host "Testing complete DevOps KnowledgeOps Agent flow..." -ForegroundColor Green

$baseUrl = "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod"

Write-Host ""
Write-Host "Step 1: Testing Authentication..." -ForegroundColor Yellow
$authPayload = '{"action":"signin","username":"demo@example.com","password":"DemoPassword123!"}'

try {
    $authResponse = Invoke-RestMethod -Uri "$baseUrl/auth" -Method POST -Body $authPayload -ContentType "application/json"
    if ($authResponse.success) {
        Write-Host "SUCCESS: Authentication working!" -ForegroundColor Green
        Write-Host "User: $($authResponse.data.user.email)" -ForegroundColor Cyan
    } else {
        throw "Authentication failed: $($authResponse.error)"
    }
} catch {
    Write-Host "FAILED: Authentication error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 2: Testing Session Creation..." -ForegroundColor Yellow
$sessionPayload = '{"action":"create"}'

try {
    $sessionResponse = Invoke-RestMethod -Uri "$baseUrl/session" -Method POST -Body $sessionPayload -ContentType "application/json"
    if ($sessionResponse.success) {
        $sessionId = $sessionResponse.sessionId
        Write-Host "SUCCESS: Session created!" -ForegroundColor Green
        Write-Host "Session ID: $sessionId" -ForegroundColor Cyan
    } else {
        throw "Session creation failed: $($sessionResponse.error)"
    }
} catch {
    Write-Host "FAILED: Session creation error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 3: Testing DevOps Chat Agent..." -ForegroundColor Yellow
$chatPayload = @{
    message = "How do I deploy a Node.js application to Kubernetes?"
    sessionId = $sessionId
} | ConvertTo-Json

try {
    Write-Host "Sending DevOps query to agent..." -ForegroundColor Cyan
    $chatResponse = Invoke-RestMethod -Uri "$baseUrl/chat" -Method POST -Body $chatPayload -ContentType "application/json"
    
    if ($chatResponse.success) {
        Write-Host "SUCCESS: Chat agent responded!" -ForegroundColor Green
        Write-Host "Response length: $($chatResponse.response.Length) characters" -ForegroundColor Cyan
        Write-Host "Response time: $($chatResponse.metadata.responseTime)ms" -ForegroundColor Cyan
        Write-Host "Agent ID: $($chatResponse.metadata.agentId)" -ForegroundColor Cyan
        
        # Show first 150 characters of response
        $preview = $chatResponse.response.Substring(0, [Math]::Min(150, $chatResponse.response.Length))
        Write-Host "Preview: $preview..." -ForegroundColor White
    } else {
        throw "Chat failed: $($chatResponse.error)"
    }
} catch {
    Write-Host "FAILED: Chat error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "COMPLETE FLOW TEST RESULTS:" -ForegroundColor Green
Write-Host "===========================" -ForegroundColor Green
Write-Host "Authentication System: WORKING" -ForegroundColor Green
Write-Host "Session Management: WORKING" -ForegroundColor Green  
Write-Host "DevOps Chat Agent: WORKING" -ForegroundColor Green
Write-Host ""
Write-Host "The DevOps KnowledgeOps Agent is fully operational!" -ForegroundColor Green
Write-Host "Ready for production use with React frontend." -ForegroundColor Cyan
Write-Host ""
Write-Host "Demo Credentials:" -ForegroundColor Yellow
Write-Host "Email: demo@example.com" -ForegroundColor White
Write-Host "Password: DemoPassword123!" -ForegroundColor White