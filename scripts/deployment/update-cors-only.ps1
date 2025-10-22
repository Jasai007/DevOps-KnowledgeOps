# Update Lambda Functions with CORS Fixes Only
Write-Host "🔧 Updating Lambda Functions with CORS Fixes" -ForegroundColor Cyan

Write-Host "`n📦 Creating deployment packages..." -ForegroundColor Yellow

# Package and deploy chat function
Write-Host "Packaging chat function..." -ForegroundColor Gray
if (Test-Path "lambda-chat-cors.zip") { Remove-Item "lambda-chat-cors.zip" }

$tempChatDir = "temp-chat-cors"
if (Test-Path $tempChatDir) { Remove-Item -Recurse -Force $tempChatDir }
New-Item -ItemType Directory -Path $tempChatDir | Out-Null

# Copy chat files
Copy-Item "lambda/chat/agentcore-chat.js" "$tempChatDir/"
Copy-Item "lambda/chat/agentcore-gateway.js" "$tempChatDir/"

# Copy memory files
New-Item -ItemType Directory -Path "$tempChatDir/memory" | Out-Null
Copy-Item "lambda/memory/memory-manager.js" "$tempChatDir/memory/"

# Create package.json
@"
{
  "name": "devops-agent-chat-cors",
  "version": "1.0.0",
  "dependencies": {
    "@aws-sdk/client-bedrock-agent-runtime": "^3.450.0",
    "@aws-sdk/client-dynamodb": "^3.450.0",
    "@aws-sdk/lib-dynamodb": "^3.450.0"
  }
}
"@ | Out-File -FilePath "$tempChatDir/package.json" -Encoding UTF8

Compress-Archive -Path "$tempChatDir/*" -DestinationPath "lambda-chat-cors.zip"
Remove-Item -Recurse -Force $tempChatDir

# Package auth function
Write-Host "Packaging auth function..." -ForegroundColor Gray
if (Test-Path "lambda-auth-cors.zip") { Remove-Item "lambda-auth-cors.zip" }
Compress-Archive -Path "lambda/auth/*" -DestinationPath "lambda-auth-cors.zip"

# Package session function
Write-Host "Packaging session function..." -ForegroundColor Gray
if (Test-Path "lambda-session-cors.zip") { Remove-Item "lambda-session-cors.zip" }
Compress-Archive -Path "lambda/session/*" -DestinationPath "lambda-session-cors.zip"

Write-Host "`n🚀 Deploying to AWS Lambda..." -ForegroundColor Yellow

# List available functions first
Write-Host "Available Lambda functions:" -ForegroundColor Gray
aws lambda list-functions --query "Functions[].FunctionName" --output table

Write-Host "`n✅ Packages created successfully!" -ForegroundColor Green
Write-Host "Chat package: lambda-chat-cors.zip" -ForegroundColor Gray
Write-Host "Auth package: lambda-auth-cors.zip" -ForegroundColor Gray
Write-Host "Session package: lambda-session-cors.zip" -ForegroundColor Gray

Write-Host "`n📋 Manual Deployment Instructions:" -ForegroundColor Yellow
Write-Host "1. Go to AWS Lambda Console" -ForegroundColor Gray
Write-Host "2. Find your chat function (likely named devops-agent-chat or similar)" -ForegroundColor Gray
Write-Host "3. Upload lambda-chat-cors.zip" -ForegroundColor Gray
Write-Host "4. Repeat for auth and session functions" -ForegroundColor Gray

Write-Host "`n🎯 CORS Headers Added:" -ForegroundColor Cyan
Write-Host "- Access-Control-Allow-Origin: *" -ForegroundColor Green
Write-Host "- Access-Control-Allow-Headers: Enhanced" -ForegroundColor Green
Write-Host "- Access-Control-Allow-Methods: All methods" -ForegroundColor Green
Write-Host "- Access-Control-Max-Age: 86400" -ForegroundColor Green
Write-Host "- Proper OPTIONS handling" -ForegroundColor Green

Write-Host "`nTest the frontend again after deployment!" -ForegroundColor White