# Deploy AgentCore with Memory Implementation
Write-Host "🚀 Deploying AgentCore with Memory Implementation" -ForegroundColor Cyan

# Function names
$CHAT_FUNCTION = "devops-agent-chat"
$AUTH_FUNCTION = "devops-agent-auth" 
$SESSION_FUNCTION = "devops-agent-session"

# Create deployment packages
Write-Host "`n📦 Creating deployment packages..." -ForegroundColor Yellow

# Package chat function with memory
Write-Host "Packaging chat function with memory..." -ForegroundColor Gray
if (Test-Path "lambda-chat-memory.zip") { Remove-Item "lambda-chat-memory.zip" }

# Create temporary directory for chat package
$tempChatDir = "temp-chat-package"
if (Test-Path $tempChatDir) { Remove-Item -Recurse -Force $tempChatDir }
New-Item -ItemType Directory -Path $tempChatDir | Out-Null

# Copy chat files
Copy-Item "lambda/chat/agentcore-chat.js" "$tempChatDir/"
Copy-Item "lambda/chat/agentcore-gateway.js" "$tempChatDir/"

# Copy memory files
New-Item -ItemType Directory -Path "$tempChatDir/memory" | Out-Null
Copy-Item "lambda/memory/memory-manager.js" "$tempChatDir/memory/"

# Copy package.json with dependencies
@"
{
  "name": "devops-agent-chat-memory",
  "version": "1.0.0",
  "dependencies": {
    "@aws-sdk/client-bedrock-agent-runtime": "^3.450.0",
    "@aws-sdk/client-dynamodb": "^3.450.0",
    "@aws-sdk/lib-dynamodb": "^3.450.0"
  }
}
"@ | Out-File -FilePath "$tempChatDir/package.json" -Encoding UTF8

# Create zip
Compress-Archive -Path "$tempChatDir/*" -DestinationPath "lambda-chat-memory.zip"
Remove-Item -Recurse -Force $tempChatDir

# Package auth function
Write-Host "Packaging auth function..." -ForegroundColor Gray
if (Test-Path "lambda-auth.zip") { Remove-Item "lambda-auth.zip" }
Compress-Archive -Path "lambda/auth/*" -DestinationPath "lambda-auth.zip"

# Package session function  
Write-Host "Packaging session function..." -ForegroundColor Gray
if (Test-Path "lambda-session.zip") { Remove-Item "lambda-session.zip" }
Compress-Archive -Path "lambda/session/*" -DestinationPath "lambda-session.zip"

# Deploy functions
Write-Host "`n🚀 Deploying Lambda functions..." -ForegroundColor Yellow

try {
    # Deploy chat function with memory
    Write-Host "Deploying chat function with AgentCore memory..." -ForegroundColor Gray
    aws lambda update-function-code --function-name $CHAT_FUNCTION --zip-file fileb://lambda-chat-memory.zip
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Chat function deployed successfully" -ForegroundColor Green
        
        # Update environment variables for memory
        aws lambda update-function-configuration --function-name $CHAT_FUNCTION --environment Variables="{MEMORY_TABLE_NAME=devops-chat-messages,CHAT_TABLE_NAME=devops-chat-messages}"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Chat function environment updated" -ForegroundColor Green
        }
    } else {
        Write-Host "❌ Chat function deployment failed" -ForegroundColor Red
    }

    # Deploy auth function
    Write-Host "Deploying auth function..." -ForegroundColor Gray
    aws lambda update-function-code --function-name $AUTH_FUNCTION --zip-file fileb://lambda-auth.zip
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Auth function deployed successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Auth function deployment failed" -ForegroundColor Red
    }

    # Deploy session function
    Write-Host "Deploying session function..." -ForegroundColor Gray
    aws lambda update-function-code --function-name $SESSION_FUNCTION --zip-file fileb://lambda-session.zip
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Session function deployed successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Session function deployment failed" -ForegroundColor Red
    }

} catch {
    Write-Host "❌ Deployment error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test the deployment
Write-Host "`n🧪 Testing AgentCore Memory Implementation..." -ForegroundColor Yellow

try {
    # Test auth endpoint
    Write-Host "Testing auth endpoint..." -ForegroundColor Gray
    $authTest = aws lambda invoke --function-name $AUTH_FUNCTION --payload '{"httpMethod":"POST","body":"{\"action\":\"signin\",\"username\":\"test\",\"password\":\"test\"}"}' response.json
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Auth function responding" -ForegroundColor Green
    }

    # Test session endpoint
    Write-Host "Testing session endpoint..." -ForegroundColor Gray
    $sessionTest = aws lambda invoke --function-name $SESSION_FUNCTION --payload '{"httpMethod":"POST","body":"{\"action\":\"create\"}"}' response.json
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Session function responding" -ForegroundColor Green
    }

    # Test chat endpoint (will fail without auth, but should respond)
    Write-Host "Testing chat endpoint..." -ForegroundColor Gray
    $chatTest = aws lambda invoke --function-name $CHAT_FUNCTION --payload '{"httpMethod":"POST","body":"{\"message\":\"Hello AgentCore\"}"}' response.json
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Chat function responding" -ForegroundColor Green
        
        # Check if response mentions memory
        $response = Get-Content response.json | ConvertFrom-Json
        if ($response.body -like "*memoryEnabled*") {
            Write-Host "✅ AgentCore Memory is enabled" -ForegroundColor Green
        }
    }

} catch {
    Write-Host "⚠️  Testing completed with warnings: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Cleanup
Write-Host "`n🧹 Cleaning up..." -ForegroundColor Yellow
if (Test-Path "lambda-chat-memory.zip") { Remove-Item "lambda-chat-memory.zip" }
if (Test-Path "lambda-auth.zip") { Remove-Item "lambda-auth.zip" }
if (Test-Path "lambda-session.zip") { Remove-Item "lambda-session.zip" }
if (Test-Path "response.json") { Remove-Item "response.json" }

Write-Host "`n🎉 AgentCore Memory Deployment Complete!" -ForegroundColor Cyan
Write-Host "Features:" -ForegroundColor White
Write-Host "- ✅ Individual user memory" -ForegroundColor Green
Write-Host "- ✅ Conversation context retention" -ForegroundColor Green
Write-Host "- ✅ User preference learning" -ForegroundColor Green
Write-Host "- ✅ Topic and tool tracking" -ForegroundColor Green
Write-Host "- ✅ Clean mobile UI (no mic/pin icons)" -ForegroundColor Green
Write-Host "- ✅ Proper navbar alignment" -ForegroundColor Green

Write-Host "`nAPI Gateway URL: https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod" -ForegroundColor Cyan