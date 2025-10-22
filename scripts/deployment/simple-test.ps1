# Simple Test for AgentCore Memory Application
Write-Host "🧪 Testing AgentCore Memory Application" -ForegroundColor Cyan

# Test 1: Compile Memory Manager
Write-Host "`n1. Compiling Memory Manager..." -ForegroundColor Yellow
npx tsc lambda/memory/memory-manager.ts --target es2020 --module commonjs --outDir lambda/memory

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Memory manager compiled successfully" -ForegroundColor Green
} else {
    Write-Host "❌ Memory manager compilation failed" -ForegroundColor Red
}

# Test 2: Check Files
Write-Host "`n2. Checking Key Files..." -ForegroundColor Yellow

$files = @(
    "lambda/memory/memory-manager.js",
    "lambda/chat/agentcore-chat.js",
    "frontend/src/services/api.ts",
    "frontend/src/components/Chat/ChatInput.tsx",
    "frontend/src/components/Header/Header.tsx"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "✅ $file exists" -ForegroundColor Green
    } else {
        Write-Host "❌ $file missing" -ForegroundColor Red
    }
}

# Test 3: Check Mobile UI Fixes
Write-Host "`n3. Checking Mobile UI Fixes..." -ForegroundColor Yellow

$chatInputContent = Get-Content "frontend/src/components/Chat/ChatInput.tsx" -Raw
if ($chatInputContent -notlike "*MicIcon*") {
    Write-Host "✅ Mic icon removed from ChatInput" -ForegroundColor Green
} else {
    Write-Host "❌ Mic icon still present" -ForegroundColor Red
}

if ($chatInputContent -notlike "*AttachIcon*") {
    Write-Host "✅ Attach icon removed from ChatInput" -ForegroundColor Green
} else {
    Write-Host "❌ Attach icon still present" -ForegroundColor Red
}

# Test 4: Check API Configuration
Write-Host "`n4. Checking API Configuration..." -ForegroundColor Yellow

$apiContent = Get-Content "frontend/src/services/api.ts" -Raw
if ($apiContent -like "*66a22b8wlb.execute-api.us-east-1.amazonaws.com*") {
    Write-Host "✅ API URL configured for Lambda functions" -ForegroundColor Green
} else {
    Write-Host "❌ API URL not configured correctly" -ForegroundColor Red
}

# Test 5: Check Memory Integration
Write-Host "`n5. Checking Memory Integration..." -ForegroundColor Yellow

$chatContent = Get-Content "lambda/chat/agentcore-chat.js" -Raw
if ($chatContent -like "*MemoryManager*") {
    Write-Host "✅ Memory Manager imported in chat handler" -ForegroundColor Green
} else {
    Write-Host "❌ Memory Manager not imported" -ForegroundColor Red
}

if ($chatContent -like "*memoryEnabled*") {
    Write-Host "✅ Memory enabled flag in response" -ForegroundColor Green
} else {
    Write-Host "❌ Memory enabled flag missing" -ForegroundColor Red
}

Write-Host "`n🎉 Test Complete!" -ForegroundColor Cyan
Write-Host "Ready to deploy with: ./scripts/deployment/deploy-agentcore-memory.ps1" -ForegroundColor White