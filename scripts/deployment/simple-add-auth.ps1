# Simple script to add auth endpoint
$API_ID = "66a22b8wlb"

Write-Host "Adding auth endpoint..." -ForegroundColor Yellow

# Get root resource
$resources = aws apigateway get-resources --rest-api-id $API_ID --output json | ConvertFrom-Json
$rootId = ($resources.items | Where-Object { $_.path -eq "/" }).id

# Create auth resource
aws apigateway create-resource --rest-api-id $API_ID --parent-id $rootId --path-part "auth" 2>$null

# Get auth resource ID
$resources = aws apigateway get-resources --rest-api-id $API_ID --output json | ConvertFrom-Json
$authId = ($resources.items | Where-Object { $_.pathPart -eq "auth" }).id

if ($authId) {
    Write-Host "Auth resource ID: $authId" -ForegroundColor Gray
    
    # Add POST method
    aws apigateway put-method --rest-api-id $API_ID --resource-id $authId --http-method POST --authorization-type NONE --no-cli-pager 2>$null
    
    # Add integration
    $uri = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:992382848863:function:cors-auth-final/invocations"
    aws apigateway put-integration --rest-api-id $API_ID --resource-id $authId --http-method POST --type AWS_PROXY --integration-http-method POST --uri $uri --no-cli-pager 2>$null
    
    # Add permission
    aws lambda add-permission --function-name cors-auth-final --statement-id "api-auth-$(Get-Random)" --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:us-east-1:992382848863:${API_ID}/*/*" --no-cli-pager 2>$null
    
    # Deploy
    aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod --no-cli-pager 2>$null
    
    Write-Host "✅ Auth endpoint added!" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to create auth resource" -ForegroundColor Red
}