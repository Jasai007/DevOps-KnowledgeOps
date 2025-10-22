# Add Session Endpoint to API Gateway
$API_ID = "66a22b8wlb"

Write-Host "🔧 Adding session endpoint..." -ForegroundColor Cyan

# Get root resource ID
$resources = aws apigateway get-resources --rest-api-id $API_ID --output json | ConvertFrom-Json
$rootId = ($resources.items | Where-Object { $_.path -eq "/" }).id

# Create session resource
Write-Host "Creating /session resource..." -ForegroundColor Yellow
$sessionResource = aws apigateway create-resource --rest-api-id $API_ID --parent-id $rootId --path-part "session" --output json | ConvertFrom-Json
$sessionId = $sessionResource.id

Write-Host "Session resource created: $sessionId" -ForegroundColor Gray

# Add POST method (public for now)
Write-Host "Adding POST method..." -ForegroundColor Yellow
aws apigateway put-method --rest-api-id $API_ID --resource-id $sessionId --http-method POST --authorization-type NONE --no-cli-pager

# Add integration to session Lambda
Write-Host "Adding Lambda integration..." -ForegroundColor Yellow
$sessionUri = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:992382848863:function:simple-session-handler/invocations"
aws apigateway put-integration --rest-api-id $API_ID --resource-id $sessionId --http-method POST --type AWS_PROXY --integration-http-method POST --uri $sessionUri --no-cli-pager

# Add Lambda permission
Write-Host "Adding Lambda permission..." -ForegroundColor Yellow
aws lambda add-permission --function-name simple-session-handler --statement-id "api-session-$(Get-Random)" --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:us-east-1:992382848863:${API_ID}/*/*" --no-cli-pager 2>$null

# Deploy API
Write-Host "Deploying API..." -ForegroundColor Yellow
aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod --no-cli-pager

Write-Host "✅ Session endpoint added successfully!" -ForegroundColor Green