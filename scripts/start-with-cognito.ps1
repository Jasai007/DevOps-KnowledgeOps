# Start DevOps KnowledgeOps with Cognito Authentication
Write-Host "🚀 Starting DevOps KnowledgeOps with Cognito Authentication..." -ForegroundColor Green
Write-Host ""

# Load Cognito configuration from backend/config
$configPath = "backend/config/cognito-config.env"

if (Test-Path $configPath) {
    Write-Host "📋 Loading Cognito configuration from $configPath..." -ForegroundColor Cyan
    
    Get-Content $configPath | ForEach-Object {
        if ($_ -match '^([^#][^=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            Set-Item -Path "env:$name" -Value $value
            Write-Host "  ✅ $name = $value" -ForegroundColor Gray
        }
    }
    Write-Host ""
} else {
    Write-Host "⚠️  Cognito config not found at $configPath" -ForegroundColor Yellow
    Write-Host "Using default values..." -ForegroundColor Yellow
    
    # Set default values
    $env:AWS_REGION = "us-east-1"
    $env:USER_POOL_ID = "us-east-1_QVdUR725D"
    $env:USER_POOL_CLIENT_ID = "7a283i8pqhq7h1k88me51gsefo"
    $env:BEDROCK_AGENT_ID = "MNJESZYALW"
    Write-Host ""
}

Write-Host "🔧 Configuration Summary:" -ForegroundColor Cyan
Write-Host "  AWS Region: $env:AWS_REGION" -ForegroundColor White
Write-Host "  User Pool ID: $env:USER_POOL_ID" -ForegroundColor White
Write-Host "  Client ID: $env:USER_POOL_CLIENT_ID" -ForegroundColor White
Write-Host "  Bedrock Agent ID: $env:BEDROCK_AGENT_ID" -ForegroundColor White
Write-Host ""

Write-Host "👥 Demo Cognito Users Available:" -ForegroundColor Cyan
Write-Host "  📧 demo@example.com / 🔑 Demo123!" -ForegroundColor White
Write-Host "  📧 admin@example.com / 🔑 Admin123!" -ForegroundColor White
Write-Host "  📧 user1@example.com / 🔑 User123!" -ForegroundColor White
Write-Host ""

# Function to start backend with Cognito
function Start-BackendWithCognito {
    Write-Host "🔧 Starting Backend API Server with Cognito..." -ForegroundColor Cyan
    Set-Location backend
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "node server.js" -WindowStyle Normal
    Set-Location ..
    Write-Host "✅ Backend started with Cognito authentication" -ForegroundColor Green
}

# Function to start frontend
function Start-Frontend {
    Write-Host "🎨 Starting Frontend React App..." -ForegroundColor Cyan
    Set-Location frontend
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "npm start" -WindowStyle Normal
    Set-Location ..
    Write-Host "✅ Frontend started" -ForegroundColor Green
}

# Start both services
Start-BackendWithCognito
Start-Sleep -Seconds 3
Start-Frontend

Write-Host ""
Write-Host "🎉 DevOps KnowledgeOps Agent with Cognito is starting up!" -ForegroundColor Green
Write-Host ""
Write-Host "📱 Frontend: http://localhost:3000" -ForegroundColor Yellow
Write-Host "🔧 Backend API: http://localhost:3001" -ForegroundColor Yellow
Write-Host "🏥 Health Check: http://localhost:3001/health" -ForegroundColor Yellow
Write-Host "🔐 Demo Credentials: http://localhost:3001/demo-credentials" -ForegroundColor Yellow
Write-Host ""
Write-Host "🧪 To test conversation memory:" -ForegroundColor Cyan
Write-Host "   node test-conversation-memory.js" -ForegroundColor White
Write-Host ""
Write-Host "🔐 Login with any of the demo users above!" -ForegroundColor Green
Write-Host "⏹️  To stop: Close the PowerShell windows or press Ctrl+C in each" -ForegroundColor Red
Write-Host ""
Write-Host "Happy DevOps-ing with Cognito! 🚀" -ForegroundColor Green