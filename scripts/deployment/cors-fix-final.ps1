Write-Host "Fixing session CORS..." -ForegroundColor Green

# Get API info
$apiId = "66a22b8wlb"
$resourceId = "tdrqda"

Write-Host "API ID: $apiId"
Write-Host "Resource ID: $resourceId"

# Create temp JSON files for complex parameters
$integrationTemplate = @{
    "application/json" = '{"statusCode": 200}'
} | ConvertTo-Json -Compress

$integrationResponse = @{
    "method.response.header.Access-Control-Allow-Headers" = "Content-Type,Authorization"
    "method.response.header.Access-Control-Allow-Methods" = "GET,POST,OPTIONS"
    "method.response.header.Access-Control-Allow-Origin" = "*"
} | ConvertTo-Json -Compress

$responseTemplates = @{
    "application/json" = ""
} | ConvertTo-Json -Compress

# Write to temp files
$integrationTemplate | Out-File -FilePath "temp-integration.json" -Encoding UTF8
$integrationResponse | Out-File -FilePath "temp-response-params.json" -Encoding UTF8
$responseTemplates | Out-File -FilePath "temp-response-templates.json" -Encoding UTF8

# Add integration
Write-Host "Adding mock integration..."
aws apigateway put-integration --rest-api-id $apiId --resource-id $resourceId --http-method OPTIONS --type MOCK --request-templates file://temp-integration.json

# Add integration response
Write-Host "Adding integration response..."
aws apigateway put-integration-response --rest-api-id $apiId --resource-id $resourceId --http-method OPTIONS --status-code 200 --response-parameters file://temp-response-params.json --response-templates file://temp-response-templates.json

# Deploy
Write-Host "Deploying..."
aws apigateway create-deployment --rest-api-id $apiId --stage-name prod

# Cleanup
Remove-Item "temp-*.json" -Force

Write-Host "Testing CORS fix..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

try {
    $response = Invoke-WebRequest -Uri "https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/session" -Method OPTIONS
    Write-Host "SUCCESS! Status:" $response.StatusCode -ForegroundColor Green
} catch {
    Write-Host "Still failing:" $_.Exception.Message -ForegroundColor Red
}

Write-Host "CORS fix complete!" -ForegroundColor Green