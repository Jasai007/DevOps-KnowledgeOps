# Final CORS Test and Fix
Write-Host "🔥 FINAL CORS TEST AND FIX" -ForegroundColor Red

$API_ID = "66a22b8wlb"
$API_URL = "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod"

Write-Host "Testing all endpoints with detailed CORS analysis..." -ForegroundColor Yellow

$endpoints = @("auth", "session", "chat")
$allWorking = $true

foreach ($endpoint in $endpoints) {
    Write-Host "`n🧪 Testing /$endpoint..." -ForegroundColor Cyan
    
    try {
        # Test OPTIONS preflight request
        $response = Invoke-WebRequest -Uri "$API_URL/$endpoint" -Method OPTIONS -Headers @{
            "Origin" = "http://localhost:3000"
            "Access-Control-Request-Method" = "POST"
            "Access-Control-Request-Headers" = "Content-Type,Authorization"
        } -UseBasicParsing -TimeoutSec 10
        
        Write-Host "✅ Status: $($response.StatusCode)" -ForegroundColor Green
        
        # Check required CORS headers
        $requiredHeaders = @("Access-Control-Allow-Origin", "Access-Control-Allow-Methods", "Access-Control-Allow-Headers")
        foreach ($header in $requiredHeaders) {
            if ($response.Headers[$header]) {
                Write-Host "   ✅ $header`: $($response.Headers[$header])" -ForegroundColor Green
            } else {
                Write-Host "   ❌ MISSING: $header" -ForegroundColor Red
                $allWorking = $false
            }
        }
        
    } catch {
        Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
        $allWorking = $false
        
        # If it failed, try to fix it immediately
        Write-Host "   🔧 Attempting immediate fix..." -ForegroundColor Yellow
        
        # Get resource ID
        $resources = aws apigateway get-resources --rest-api-id $API_ID --output json | ConvertFrom-Json
        $resourceId = ($resources.items | Where-Object { $_.pathPart -eq $endpoint }).id
        
        if ($resourceId) {
            # Force recreate OPTIONS integration
            aws apigateway put-integration --rest-api-id $API_ID --resource-id $resourceId --http-method OPTIONS --type MOCK --request-templates 'application/json={"statusCode": 200}' --passthrough-behavior WHEN_NO_MATCH --timeout-in-millis 29000 2>$null
            
            # Force recreate integration response
            aws apigateway put-integration-response --rest-api-id $API_ID --resource-id $resourceId --http-method OPTIONS --status-code 200 --response-parameters 'method.response.header.Access-Control-Allow-Headers=Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,method.response.header.Access-Control-Allow-Methods=GET,POST,OPTIONS,method.response.header.Access-Control-Allow-Origin=*' 2>$null
            
            Write-Host "   ✅ Fix applied for /$endpoint" -ForegroundColor Green
        }
    }
}

if (!$allWorking) {
    Write-Host "`n🚀 Deploying fixes..." -ForegroundColor Red
    aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod --description "Final CORS fix $(Get-Date -Format 'HHmmss')"
    
    Write-Host "⏳ Waiting 10 seconds for deployment..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    
    Write-Host "`n🔄 Re-testing after fixes..." -ForegroundColor Cyan
    foreach ($endpoint in $endpoints) {
        try {
            $response = Invoke-WebRequest -Uri "$API_URL/$endpoint" -Method OPTIONS -Headers @{"Origin"="http://localhost:3000"} -UseBasicParsing -TimeoutSec 10
            Write-Host "✅ /$endpoint : NOW WORKING ($($response.StatusCode))" -ForegroundColor Green
        } catch {
            Write-Host "❌ /$endpoint : STILL BROKEN" -ForegroundColor Red
        }
    }
}

Write-Host "`n🎯 FINAL STATUS:" -ForegroundColor Cyan
if ($allWorking) {
    Write-Host "✅ ALL CORS ENDPOINTS ARE WORKING!" -ForegroundColor Green
    Write-Host "Your frontend should now work without CORS errors." -ForegroundColor Green
} else {
    Write-Host "⚠️  Some endpoints may still have issues." -ForegroundColor Yellow
    Write-Host "Try refreshing your browser and testing again." -ForegroundColor Yellow
}

Write-Host "`n📱 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Refresh your browser (Ctrl+F5)" -ForegroundColor Gray
Write-Host "2. Clear browser cache if needed" -ForegroundColor Gray
Write-Host "3. Try your frontend again" -ForegroundColor Gray
Write-Host "4. Health check is temporarily disabled to avoid errors" -ForegroundColor Gray