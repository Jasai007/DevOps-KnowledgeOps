# Smart DevOps KnowledgeOps Startup Script
# Tests Bedrock Agent and falls back if needed

Write-Host "🚀 Smart DevOps KnowledgeOps Agent Startup" -ForegroundColor Green
Write-Host ""

# Load configuration
$configPath = "backend/config/cognito-config.env"
if (Test-Path $configPath) {
    Write-Host "📋 Loading configuration from $configPath..." -ForegroundColor Cyan
    Get-Content $configPath | ForEach-Object {
        if ($_ -match '^([^#][^=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            Set-Item -Path "env:$name" -Value $value
        }
    }
} else {
    Write-Host "⚠️  Config file not found, using defaults..." -ForegroundColor Yellow
    $env:AWS_REGION = "us-east-1"
    $env:BEDROCK_AGENT_ID = "MNJESZYALW"
    $env:USER_POOL_ID = "us-east-1_QVdUR725D"
    $env:USER_POOL_CLIENT_ID = "7a283i8pqhq7h1k88me51gsefo"
    $env:USER_POOL_CLIENT_SECRET = "vr0eledlg9ok3db66t3ktpmq7d0095o0a1moqv78ikjsv0mnp8m"
}

Write-Host ""

# Test AWS credentials
Write-Host "🔐 Testing AWS credentials..." -ForegroundColor Cyan
try {
    $awsTest = aws sts get-caller-identity 2>$null
    if ($LASTEXITCODE -eq 0) {
        $awsInfo = $awsTest | ConvertFrom-Json
        Write-Host "✅ AWS credentials valid" -ForegroundColor Green
        Write-Host "   Account: $($awsInfo.Account)" -ForegroundColor Gray
        Write-Host "   User: $($awsInfo.Arn)" -ForegroundColor Gray
        $awsConfigured = $true
    } else {
        throw "AWS CLI failed"
    }
} catch {
    Write-Host "❌ AWS credentials not configured" -ForegroundColor Red
    Write-Host "   Will use fallback mode" -ForegroundColor Yellow
    $awsConfigured = $false
}

Write-Host ""

# Test Bedrock Agent
$useFullAgent = $false
if ($awsConfigured) {
    Write-Host "🤖 Testing Bedrock Agent..." -ForegroundColor Cyan
    try {
        # Quick test of Bedrock Agent
        Write-Host "   Testing agent: $env:BEDROCK_AGENT_ID" -ForegroundColor Gray
        
        # Run the Bedrock test script
        $testResult = node tests/test-bedrock-agent.js 2>&1
        
        if ($testResult -match "Agent responded successfully") {
            Write-Host "✅ Bedrock Agent is working" -ForegroundColor Green
            $useFullAgent = $true
        } else {
            Write-Host "❌ Bedrock Agent test failed" -ForegroundColor Red
            Write-Host "   Will use fallback mode" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ Bedrock Agent test error" -ForegroundColor Red
        Write-Host "   Will use fallback mode" -ForegroundColor Yellow
    }
}

Write-Host ""

# Choose server mode
if ($useFullAgent) {
    Write-Host "🚀 Starting FULL AgentCore Server..." -ForegroundColor Green
    Write-Host "   Features: Bedrock Agent + AgentCore Gateway + Memory" -ForegroundColor Cyan
    $serverFile = "server.js"
} else {
    Write-Host "🔄 Starting FALLBACK Server..." -ForegroundColor Yellow
    Write-Host "   Features: Mock responses + Basic auth + Session management" -ForegroundColor Cyan
    $serverFile = "server-fallback.js"
}

Write-Host ""

# Start backend
Write-Host "🔧 Starting backend server..." -ForegroundColor Cyan
Set-Location backend
Start-Process powershell -ArgumentList "-NoExit", "-Command", "node $serverFile" -WindowStyle Normal
Set-Location ..

Start-Sleep -Seconds 3

# Test server
Write-Host "🧪 Testing server connection..." -ForegroundColor Cyan
try {
    $healthCheck = Invoke-RestMethod -Uri "http://localhost:3001/health" -TimeoutSec 5
    if ($healthCheck.status -eq "healthy") {
        Write-Host "✅ Server is running successfully" -ForegroundColor Green
        Write-Host "   Mode: $($healthCheck.mode -or 'full')" -ForegroundColor Gray
        Write-Host "   Agent: $($healthCheck.agentId)" -ForegroundColor Gray
    }
} catch {
    Write-Host "⚠️  Server may still be starting..." -ForegroundColor Yellow
}

# Start frontend
Write-Host ""
Write-Host "🎨 Starting frontend..." -ForegroundColor Cyan
Set-Location frontend
Start-Process powershell -ArgumentList "-NoExit", "-Command", "npm start" -WindowStyle Normal
Set-Location ..

Write-Host ""
Write-Host "🎉 DevOps KnowledgeOps Agent is starting!" -ForegroundColor Green
Write-Host ""

if ($useFullAgent) {
    Write-Host "🚀 FULL MODE ACTIVE:" -ForegroundColor Green
    Write-Host "   • Bedrock Agent with AgentCore" -ForegroundColor White
    Write-Host "   • Intelligent caching and retry logic" -ForegroundColor White
    Write-Host "   • User memory and context enhancement" -ForegroundColor White
    Write-Host "   • CloudWatch metrics integration" -ForegroundColor White
} else {
    Write-Host "🔄 FALLBACK MODE ACTIVE:" -ForegroundColor Yellow
    Write-Host "   • Mock DevOps responses" -ForegroundColor White
    Write-Host "   • Basic authentication" -ForegroundColor White
    Write-Host "   • Session management" -ForegroundColor White
    Write-Host "   • Perfect for testing UI" -ForegroundColor White
}

Write-Host ""
Write-Host "📱 Frontend: http://localhost:3000" -ForegroundColor Cyan
Write-Host "🔧 Backend: http://localhost:3001" -ForegroundColor Cyan
Write-Host "🏥 Health: http://localhost:3001/health" -ForegroundColor Cyan

Write-Host ""
Write-Host "👥 Demo Users:" -ForegroundColor Cyan
Write-Host "   📧 demo@example.com / 🔑 Demo123!" -ForegroundColor White
Write-Host "   📧 admin@example.com / 🔑 Admin123!" -ForegroundColor White

Write-Host ""
Write-Host "🧪 Test Commands:" -ForegroundColor Cyan
Write-Host "   node tests/test-server-connection.js  # Test server" -ForegroundColor White
Write-Host "   node tests/test-bedrock-agent.js      # Test Bedrock Agent" -ForegroundColor White
if ($useFullAgent) {
    Write-Host "   node tests/test-agentcore.js          # Test AgentCore features" -ForegroundColor White
}

Write-Host ""
Write-Host "Happy DevOps-ing! 🚀" -ForegroundColor Green