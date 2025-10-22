# Simple API Gateway CORS Fix
Write-Host "Fixing API Gateway CORS..." -ForegroundColor Cyan

$API_ID = "uvhylyixu1"

# Get resources
Write-Host "Getting API Gateway resources..." -ForegroundColor Yellow
$resources = aws apigateway get-resources --rest-api-id $API_ID --output json | ConvertFrom-Json

# Configure CORS for each resource
foreach ($resource in $resources.items) {
    if ($resource.pathPart -and $resource.pathPart -ne "None") {
        $resourceId = $resource.id
        $path = $resource.pathPart
        
        Write-Host "Configuring CORS for /$path..." -ForegroundColor Gray
        
        # Add OPTIONS method
        aws apigateway put-method --rest-api-id $API_ID --resource-id $resourceId --http-method OPTIONS --authorization-type NONE --no-api-key-required 2>$null
        
        # Add method response
        aws apigateway put-method-response --rest-api-id $API_ID --resource-id $resourceId --http-method OPTIONS --status-code 200 --response-parameters "method.response.header.Access-Control-Allow-Headers=false,method.response.header.Access-Control-Allow-Methods=false,method.response.header.Access-Control-Allow-Origin=false" 2>$null
        
        # Add integration
        aws apigateway put-integration --rest-api-id $API_ID --resource-id $resourceId --http-method OPTIONS --type MOCK --integration-http-method OPTIONS --request-templates "application/json={`"statusCode`": 200}" 2>$null
        
        # Add integration response
        aws apigateway put-integration-response --rest-api-id $API_ID --resource-id $resourceId --http-method OPTIONS --status-code 200 --response-parameters "method.response.header.Access-Control-Allow-Headers='Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Requested-With',method.response.header.Access-Control-Allow-Methods='GET,POST,OPTIONS,PUT,DELETE,PATCH',method.response.header.Access-Control-Allow-Origin='*'" 2>$null
        
        Write-Host "CORS configured for /$path" -ForegroundColor Green
    }
}

# Deploy API Gateway
Write-Host "Deploying API Gateway..." -ForegroundColor Yellow
aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod --description "CORS fix deployment"

Write-Host "API Gateway CORS fix complete!" -ForegroundColor Green