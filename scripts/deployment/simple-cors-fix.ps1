# Simple CORS Fix - Create Deployment Packages
Write-Host "Creating CORS-fixed deployment packages..." -ForegroundColor Cyan

# Create chat package
Write-Host "Creating chat package..." -ForegroundColor Yellow
if (Test-Path "lambda-chat-cors.zip") { Remove-Item "lambda-chat-cors.zip" }

$tempDir = "temp-chat"
if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir }
New-Item -ItemType Directory -Path $tempDir | Out-Null

Copy-Item "lambda/chat/agentcore-chat.js" "$tempDir/"
Copy-Item "lambda/chat/agentcore-gateway.js" "$tempDir/"

New-Item -ItemType Directory -Path "$tempDir/memory" | Out-Null
Copy-Item "lambda/memory/memory-manager.js" "$tempDir/memory/"

$packageJson = @"
{
  "name": "devops-agent-chat-cors",
  "version": "1.0.0",
  "dependencies": {
    "@aws-sdk/client-bedrock-agent-runtime": "^3.450.0",
    "@aws-sdk/client-dynamodb": "^3.450.0",
    "@aws-sdk/lib-dynamodb": "^3.450.0"
  }
}
"@

$packageJson | Out-File -FilePath "$tempDir/package.json" -Encoding UTF8

Compress-Archive -Path "$tempDir/*" -DestinationPath "lambda-chat-cors.zip"
Remove-Item -Recurse -Force $tempDir

Write-Host "Chat package created: lambda-chat-cors.zip" -ForegroundColor Green

# Create auth package
Write-Host "Creating auth package..." -ForegroundColor Yellow
if (Test-Path "lambda-auth-cors.zip") { Remove-Item "lambda-auth-cors.zip" }
Compress-Archive -Path "lambda/auth/*" -DestinationPath "lambda-auth-cors.zip"
Write-Host "Auth package created: lambda-auth-cors.zip" -ForegroundColor Green

# Create session package
Write-Host "Creating session package..." -ForegroundColor Yellow
if (Test-Path "lambda-session-cors.zip") { Remove-Item "lambda-session-cors.zip" }
Compress-Archive -Path "lambda/session/*" -DestinationPath "lambda-session-cors.zip"
Write-Host "Session package created: lambda-session-cors.zip" -ForegroundColor Green

Write-Host "`nCORS fixes applied to all Lambda functions!" -ForegroundColor Cyan
Write-Host "Upload these packages to your Lambda functions in AWS Console." -ForegroundColor White