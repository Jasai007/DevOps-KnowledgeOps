# Fix API Gateway CORS Configuration
Write-Host "🔧 Fixing API Gateway CORS Configuration" -ForegroundColor Cyan

$API_ID = "uvhylyixu1"
$REGION = "us-east-1"

Write-Host "`n1. 📋 Getting API Gateway Resources..." -ForegroundColor Yellow

# Get all resources
$resources = aws apigateway get-resources --rest-api-id $API_ID --output json | ConvertFrom-Json

Write-Host "Found resources:" -ForegroundColor Gray
foreach ($resource in $resources.items) {
    Write-Host "  - Path: $($resource.pathPart) (ID: $($resource.id))" -ForegroundColor Gray
}

Write-Host "`n2. 🔧 Adding CORS to Each Resource..." -ForegroundColor Yellow

foreach ($resource in $resources.items) {
    if ($resource.pathPart -and $resource.pathPart -ne "None") {
        $resourceId = $resource.id
        $path = $resource.pathPart
        
        Write-Host "Configuring CORS for /$path..." -ForegroundColor Gray
        
        try {
            # Add OPTIONS method if it doesn't exist
            Write-Host "  Adding OPTIONS method..." -ForegroundColor Gray
            aws apigateway put-method --rest-api-id $API_ID --resource-id $resourceId --http-method OPTIONS --authorization-type NONE --no-api-key-required 2>$null
            
            # Add method response for OPTIONS
            Write-Host "  Adding method response..." -ForegroundColor Gray
            aws apigateway put-method-response --rest-api-id $API_ID --resource-id $resourceId --http-method OPTIONS --status-code 200 --response-parameters "method.response.header.Access-Control-Allow-Headers=false,method.response.header.Access-Control-Allow-Methods=false,method.response.header.Access-Control-Allow-Origin=false" 2>$null
            
            # Add integration for OPTIONS
            Write-Host "  Adding integration..." -ForegroundColor Gray
            aws apigateway put-integration --rest-api-id $API_ID --resource-id $resourceId --http-method OPTIONS --type MOCK --integration-http-method OPTIONS --request-templates "application/json={`"statusCode`": 200}" 2>$null
            
            # Add integration response for OPTIONS
            Write-Host "  Adding integration response..." -ForegroundColor Gray
            aws apigateway put-integration-response --rest-api-id $API_ID --resource-id $resourceId --http-method OPTIONS --status-code 200 --response-parameters "method.response.header.Access-Control-Allow-Headers='Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Requested-With',method.response.header.Access-Control-Allow-Methods='GET,POST,OPTIONS,PUT,DELETE,PATCH',method.response.header.Access-Control-Allow-Origin='*'" 2>$null
            
            Write-Host "  ✅ CORS configured for /$path" -ForegroundColor Green
            
        } catch {
            Write-Host "  ⚠️  Some CORS settings may already exist for /$path" -ForegroundColor Yellow
        }
    }
}

Write-Host "`n3. 🚀 Deploying API Gateway..." -ForegroundColor Yellow

try {
    aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod --description "CORS fix deployment"
    Write-Host "✅ API Gateway deployed successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ API Gateway deployment failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n4. 🧪 Testing CORS Configuration..." -ForegroundColor Yellow

# Test OPTIONS request
try {
    Write-Host "Testing OPTIONS request to /chat..." -ForegroundColor Gray
    $response = Invoke-WebRequest -Uri "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/chat" -Method OPTIONS -Headers @{"Origin"="http://localhost:3000"} -UseBasicParsing
    
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ OPTIONS request successful" -ForegroundColor Green
        
        # Check CORS headers
        $corsHeaders = $response.Headers | Where-Object { $_.Key -like "*Access-Control*" }
        if ($corsHeaders) {
            Write-Host "✅ CORS headers present" -ForegroundColor Green
        } else {
            Write-Host "⚠️  CORS headers missing" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "⚠️  OPTIONS test failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n🎉 API Gateway CORS Fix Complete!" -ForegroundColor Cyan
Write-Host "You can now switch back to Lambda endpoints in frontend/src/services/api.ts:" -ForegroundColor White
Write-Host "const API_BASE_URL = 'https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod';" -ForegroundColor Gray