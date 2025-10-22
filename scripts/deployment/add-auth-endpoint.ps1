# Add Auth Endpoint to Existing API Gateway
# Simple script to add the missing /auth endpoint

$API_ID = "66a22b8wlb"
$REGION = "us-east-1"
$ACCOUNT_ID = "992382848863"

Write-Host "🔧 Adding /auth endpoint to API Gateway..." -ForegroundColor Cyan

# Get root resource ID
$resources = aws apigateway get-resources --rest-api-id $API_ID --output json | ConvertFrom-Json
$rootResourceId = ($resources.items | Where-Object { $_.path -eq "/" }).id
Write-Host "Root Resource ID: $rootResourceId" -ForegroundColor Gray

# Create /auth resource
Write-Host "Creating /auth resource..." -ForegroundColor Yellow
$authResource = aws apigateway create-resource --rest-api-id $API_ID --parent-id $rootResourceId --path-part "auth" --output json 2>$null | ConvertFrom-Json

if ($authResource) {
    $authResourceId = $authResource.id
    Write-Host "✅ Auth resource created: $authResourceId" -ForegroundColor Green
} else {
    # Resource might already exist
    $authResourceId = ($resources.items | Where-Object { $_.pathPart -eq "auth" }).id
    if ($authResourceId) {
        Write-Host "ℹ️ Using existing auth resource: $authResourceId" -ForegroundColor Blue
    } else {
        Write-Host "❌ Failed to create or find auth resource" -ForegroundColor Red
        exit 1
    }
}

# Create POST method for /auth
Write-Host "Creating POST method for /auth..." -ForegroundColor Yellow
aws apigateway put-method --rest-api-id $API_ID --resource-id $authResourceId --http-method POST --authorization-type NONE --no-api-key-required --no-cli-pager 2>$null

# Create Lambda integration
Write-Host "Creating Lambda integration..." -ForegroundColor Yellow
$lambdaUri = "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:cors-auth-final/invocations"
aws apigateway put-integration --rest-api-id $API_ID --resource-id $authResourceId --http-method POST --type AWS_PROXY --integration-http-method POST --uri $lambdaUri --no-cli-pager 2>$null

# Add Lambda permission
Write-Host "Adding Lambda permission..." -ForegroundColor Yellow
aws lambda add-permission --function-name cors-auth-final --statement-id "apigateway-auth-invoke-$(Get-Random)" --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/*" --no-cli-pager 2>$null

# Deploy API
Write-Host "Deploying API..." -ForegroundColor Yellow
aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod --stage-description "Added auth endpoint" --no-cli-pager 2>$null

Write-Host "✅ Auth endpoint added successfully!" -ForegroundColor Green

# Test the endpoint
Write-Host "`nTesting auth endpoint..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "https://${API_ID}.execute-api.${REGION}.amazonaws.com/prod/auth" -Method POST -ContentType "application/json" -Body '{"action":"signin","username":"demo@example.com","password":"DemoPassword123!"}'
    
    if ($response.success) {
        Write-Host "✅ Auth endpoint working!" -ForegroundColor Green
        Write-Host "Access Token: $($response.accessToken.Substring(0, 20))..." -ForegroundColor Gray
    } else {
        Write-Host "❌ Auth failed: $($response.error)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Test failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🎉 Complete! Auth endpoint is now available at:" -ForegroundColor Cyan
Write-Host "https://${API_ID}.execute-api.${REGION}.amazonaws.com/prod/auth" -ForegroundColor Gray