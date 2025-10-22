#!/usr/bin/env pwsh

Write-Host "=== Deploying Cognito Integration ===" -ForegroundColor Green
Write-Host "This will update Lambda functions to use proper Cognito authentication" -ForegroundColor Yellow

# Check if we're in the right directory
if (-not (Test-Path "lambda")) {
    Write-Host "Error: Please run this script from the project root directory" -ForegroundColor Red
    exit 1
}

# Create deployment packages
Write-Host "Creating Lambda deployment packages..." -ForegroundColor Yellow

# Package session handler
Write-Host "Packaging session handler..." -ForegroundColor Cyan
cd lambda/session
if (Test-Path "session-package.zip") { Remove-Item "session-package.zip" }
Compress-Archive -Path "simple-session-handler.js", "../shared/dynamodb-storage.js" -DestinationPath "session-package.zip"

# Package chat handler  
Write-Host "Packaging chat handler..." -ForegroundColor Cyan
cd ../chat
if (Test-Path "chat-package.zip") { Remove-Item "chat-package.zip" }
Compress-Archive -Path "chat-handler.js", "../shared/agentcore-memory-enhanced.js", "../shared/dynamodb-storage.js", "agentcore-gateway.js" -DestinationPath "chat-package.zip"

cd ../..

# Update Lambda functions
Write-Host "Updating Lambda functions..." -ForegroundColor Yellow

Write-Host "Updating session handler..." -ForegroundColor Cyan
aws lambda update-function-code --function-name simple-session-handler --zip-file fileb://lambda/session/session-package.zip

Write-Host "Updating chat handler..." -ForegroundColor Cyan  
aws lambda update-function-code --function-name agentcore-simple-chat --zip-file fileb://lambda/chat/chat-package.zip

# Clean up
Write-Host "Cleaning up..." -ForegroundColor Gray
Remove-Item "lambda/session/session-package.zip" -ErrorAction SilentlyContinue
Remove-Item "lambda/chat/chat-package.zip" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "=== Deployment Complete ===" -ForegroundColor Green
Write-Host "✅ Session handler updated with Cognito authentication" -ForegroundColor White
Write-Host "✅ Chat handler updated with Cognito authentication" -ForegroundColor White
Write-Host "✅ Removed demo user dependencies" -ForegroundColor White
Write-Host ""
Write-Host "Changes made:" -ForegroundColor Cyan
Write-Host "  • User ID now extracted from Cognito JWT tokens" -ForegroundColor White
Write-Host "  • Proper authentication required for all operations" -ForegroundColor White
Write-Host "  • Sessions isolated by authenticated user" -ForegroundColor White
Write-Host "  • No more hardcoded demo users" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Restart your frontend development server" -ForegroundColor White
Write-Host "2. Sign in with your Cognito credentials" -ForegroundColor White
Write-Host "3. Test chat history with proper user isolation" -ForegroundColor White