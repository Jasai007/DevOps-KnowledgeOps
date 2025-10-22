# Deploy Clean AgentCore Lambda Functions
# This script deploys the simplified DevOps KnowledgeOps Agent with pure AgentCore functionality

Write-Host "🚀 Deploying Clean AgentCore Lambda Functions..." -ForegroundColor Green

# Configuration
$REGION = "us-east-1"
$API_GATEWAY_ID = "66a22b8wlb"
$STAGE_NAME = "prod"

# Lambda function names
$AUTH_FUNCTION = "devops-auth"
$CHAT_FUNCTION = "devops-chat"
$SESSION_FUNCTION = "devops-session"

Write-Host "📋 Configuration:" -ForegroundColor Yellow
Write-Host "  Region: $REGION"
Write-Host "  API Gateway: $API_GATEWAY_ID"
Write-Host "  Stage: $STAGE_NAME"
Write-Host ""

# Step 1: Package and deploy Auth Lambda
Write-Host "🔐 Deploying Auth Lambda Function..." -ForegroundColor Cyan

# Create deployment package for auth
$authDir = "lambda/auth"
$authZip = "auth-deployment.zip"

if (Test-Path $authZip) { Remove-Item $authZip }

# Create zip with auth handler and dependencies
Compress-Archive -Path "$authDir/auth-handler.js" -DestinationPath $authZip
Write-Host "  ✅ Auth package created: $authZip"

# Deploy auth function
try {
    aws lambda update-function-code --function-name $AUTH_FUNCTION --zip-file "fileb://$authZip" --region $REGION
    Write-Host "  ✅ Auth function updated successfully"
} catch {
    Write-Host "  ❌ Failed to update auth function: $_" -ForegroundColor Red
}

# Step 2: Package and deploy Chat Lambda
Write-Host "💬 Deploying Chat Lambda Function..." -ForegroundColor Cyan

# Create deployment package for chat
$chatDir = "lambda/chat"
$chatZip = "chat-deployment.zip"

if (Test-Path $chatZip) { Remove-Item $chatZip }

# Create zip with chat handler and AgentCore gateway
$tempChatDir = "temp-chat"
if (Test-Path $tempChatDir) { Remove-Item -Recurse $tempChatDir }
New-Item -ItemType Directory $tempChatDir

Copy-Item "$chatDir/agentcore-chat.js" $tempChatDir
Copy-Item "$chatDir/agentcore-gateway.js" $tempChatDir

Compress-Archive -Path "$tempChatDir/*" -DestinationPath $chatZip
Remove-Item -Recurse $tempChatDir
Write-Host "  ✅ Chat package created: $chatZip"

# Deploy chat function
try {
    aws lambda update-function-code --function-name $CHAT_FUNCTION --zip-file "fileb://$chatZip" --region $REGION
    Write-Host "  ✅ Chat function updated successfully"
} catch {
    Write-Host "  ❌ Failed to update chat function: $_" -ForegroundColor Red
}

# Step 3: Package and deploy Session Lambda
Write-Host "📝 Deploying Session Lambda Function..." -ForegroundColor Cyan

# Create deployment package for session
$sessionDir = "lambda/session"
$sessionZip = "session-deployment.zip"

if (Test-Path $sessionZip) { Remove-Item $sessionZip }

# Create zip with session handler
Compress-Archive -Path "$sessionDir/final-session.js" -DestinationPath $sessionZip
Write-Host "  ✅ Session package created: $sessionZip"

# Deploy session function
try {
    aws lambda update-function-code --function-name $SESSION_FUNCTION --zip-file "fileb://$sessionZip" --region $REGION
    Write-Host "  ✅ Session function updated successfully"
} catch {
    Write-Host "  ❌ Failed to update session function: $_" -ForegroundColor Red
}

# Step 4: Update API Gateway integrations
Write-Host "🌐 Updating API Gateway integrations..." -ForegroundColor Cyan

# Get API Gateway resources
$resources = aws apigateway get-resources --rest-api-id $API_GATEWAY_ID --region $REGION | ConvertFrom-Json

# Find resource IDs
$authResourceId = ($resources.items | Where-Object { $_.pathPart -eq "auth" }).id
$chatResourceId = ($resources.items | Where-Object { $_.pathPart -eq "chat" }).id
$sessionResourceId = ($resources.items | Where-Object { $_.pathPart -eq "session" }).id

Write-Host "  📍 Resource IDs:"
Write-Host "    Auth: $authResourceId"
Write-Host "    Chat: $chatResourceId"
Write-Host "    Session: $sessionResourceId"

# Update integrations to point to new Lambda functions
if ($authResourceId) {
    $authLambdaUri = "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/arn:aws:lambda:${REGION}:$(aws sts get-caller-identity --query Account --output text):function:${AUTH_FUNCTION}/invocations"
    
    try {
        aws apigateway put-integration --rest-api-id $API_GATEWAY_ID --resource-id $authResourceId --http-method POST --type AWS_PROXY --integration-http-method POST --uri $authLambdaUri --region $REGION
        Write-Host "  ✅ Auth integration updated"
    } catch {
        Write-Host "  ❌ Failed to update auth integration: $_" -ForegroundColor Red
    }
}

if ($chatResourceId) {
    $chatLambdaUri = "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/arn:aws:lambda:${REGION}:$(aws sts get-caller-identity --query Account --output text):function:${CHAT_FUNCTION}/invocations"
    
    try {
        aws apigateway put-integration --rest-api-id $API_GATEWAY_ID --resource-id $chatResourceId --http-method POST --type AWS_PROXY --integration-http-method POST --uri $chatLambdaUri --region $REGION
        Write-Host "  ✅ Chat integration updated"
    } catch {
        Write-Host "  ❌ Failed to update chat integration: $_" -ForegroundColor Red
    }
}

if ($sessionResourceId) {
    $sessionLambdaUri = "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/arn:aws:lambda:${REGION}:$(aws sts get-caller-identity --query Account --output text):function:${SESSION_FUNCTION}/invocations"
    
    try {
        aws apigateway put-integration --rest-api-id $API_GATEWAY_ID --resource-id $sessionResourceId --http-method POST --type AWS_PROXY --integration-http-method POST --uri $sessionLambdaUri --region $REGION
        Write-Host "  ✅ Session integration updated"
    } catch {
        Write-Host "  ❌ Failed to update session integration: $_" -ForegroundColor Red
    }
}

# Step 5: Deploy API Gateway
Write-Host "🚀 Deploying API Gateway..." -ForegroundColor Cyan

try {
    aws apigateway create-deployment --rest-api-id $API_GATEWAY_ID --stage-name $STAGE_NAME --region $REGION
    Write-Host "  ✅ API Gateway deployed successfully"
} catch {
    Write-Host "  ❌ Failed to deploy API Gateway: $_" -ForegroundColor Red
}

# Step 6: Test the deployment
Write-Host "🧪 Testing deployment..." -ForegroundColor Cyan

$API_BASE_URL = "https://${API_GATEWAY_ID}.execute-api.${REGION}.amazonaws.com/${STAGE_NAME}"

Write-Host "  🔗 API Base URL: $API_BASE_URL"

# Test health endpoint (if exists)
try {
    $healthResponse = Invoke-RestMethod -Uri "$API_BASE_URL/health" -Method GET -ErrorAction Stop
    Write-Host "  ✅ Health check passed" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️ Health check not available (expected for Lambda-only architecture)" -ForegroundColor Yellow
}

# Test session creation
try {
    $sessionBody = @{
        action = "create"
    } | ConvertTo-Json

    $sessionResponse = Invoke-RestMethod -Uri "$API_BASE_URL/session" -Method POST -Body $sessionBody -ContentType "application/json" -ErrorAction Stop
    
    if ($sessionResponse.success) {
        Write-Host "  ✅ Session creation test passed" -ForegroundColor Green
        Write-Host "    Session ID: $($sessionResponse.sessionId)"
    } else {
        Write-Host "  ❌ Session creation test failed: $($sessionResponse.error)" -ForegroundColor Red
    }
} catch {
    Write-Host "  ❌ Session creation test failed: $_" -ForegroundColor Red
}

# Cleanup deployment files
Write-Host "🧹 Cleaning up deployment files..." -ForegroundColor Cyan
if (Test-Path $authZip) { Remove-Item $authZip }
if (Test-Path $chatZip) { Remove-Item $chatZip }
if (Test-Path $sessionZip) { Remove-Item $sessionZip }

Write-Host ""
Write-Host "🎉 Clean AgentCore Deployment Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Summary:" -ForegroundColor Yellow
Write-Host "  ✅ Auth Lambda: $AUTH_FUNCTION"
Write-Host "  ✅ Chat Lambda: $CHAT_FUNCTION"
Write-Host "  ✅ Session Lambda: $SESSION_FUNCTION"
Write-Host "  ✅ API Gateway: $API_BASE_URL"
Write-Host ""
Write-Host "🚀 Ready to use! Start the frontend with:" -ForegroundColor Green
Write-Host "  cd frontend && npm start"
Write-Host ""
Write-Host "🔗 Test URLs:" -ForegroundColor Cyan
Write-Host "  Auth: $API_BASE_URL/auth"
Write-Host "  Chat: $API_BASE_URL/chat"
Write-Host "  Session: $API_BASE_URL/session"