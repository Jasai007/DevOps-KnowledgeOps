# Deploy Lambda Fixes
$API_ID = "66a22b8wlb"

Write-Host "🔧 Deploying Lambda fixes..." -ForegroundColor Cyan

# Create zip files
Write-Host "Creating zip files..." -ForegroundColor Gray
Compress-Archive -Path "simple-chat.js" -DestinationPath "simple-chat.zip" -Force
Compress-Archive -Path "simple-session.js" -DestinationPath "simple-session.zip" -Force

# Update chat Lambda
Write-Host "Updating chat Lambda..." -ForegroundColor Yellow
aws lambda update-function-code --function-name agentcore-simple-chat --zip-file fileb://simple-chat.zip --no-cli-pager
aws lambda update-function-configuration --function-name agentcore-simple-chat --handler simple-chat.handler --no-cli-pager

# Create session Lambda
Write-Host "Creating session Lambda..." -ForegroundColor Yellow
aws lambda create-function --function-name simple-session-handler --runtime nodejs20.x --role arn:aws:iam::992382848863:role/AgentCoreRole --handler simple-session.handler --zip-file fileb://simple-session.zip --timeout 30 --memory-size 128 --no-cli-pager 2>$null

# Add session endpoint
Write-Host "Adding session endpoint..." -ForegroundColor Yellow
$resources = aws apigateway get-resources --rest-api-id $API_ID --output json | ConvertFrom-Json
$rootId = ($resources.items | Where-Object { $_.path -eq "/" }).id
$sessionId = ($resources.items | Where-Object { $_.pathPart -eq "session" }).id

if (-not $sessionId) {
    $sessionResource = aws apigateway create-resource --rest-api-id $API_ID --parent-id $rootId --path-part "session" --output json | ConvertFrom-Json
    $sessionId = $sessionResource.id
}

aws apigateway put-method --rest-api-id $API_ID --resource-id $sessionId --http-method POST --authorization-type NONE --no-cli-pager 2>$null

$sessionUri = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:992382848863:function:simple-session-handler/invocations"
aws apigateway put-integration --rest-api-id $API_ID --resource-id $sessionId --http-method POST --type AWS_PROXY --integration-http-method POST --uri $sessionUri --no-cli-pager 2>$null

aws lambda add-permission --function-name simple-session-handler --statement-id "api-session-$(Get-Random)" --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:us-east-1:992382848863:${API_ID}/*/*" --no-cli-pager 2>$null

# Deploy API
Write-Host "Deploying API..." -ForegroundColor Yellow
aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod --no-cli-pager

Write-Host "✅ Deployment complete!" -ForegroundColor Green

# Clean up
Remove-Item "simple-chat.zip", "simple-session.zip" -ErrorAction SilentlyContinue