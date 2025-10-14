# Build script for Lambda functions (PowerShell)

Write-Host "🔨 Building Lambda functions..." -ForegroundColor Blue

# Install dependencies if needed
if (!(Test-Path "node_modules")) {
    Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
    npm install
}

# Build all TypeScript files
Write-Host "🔧 Compiling TypeScript..." -ForegroundColor Yellow
npx tsc

# Build individual Lambda functions
$lambdaDirs = @("actions", "chat-processor", "session", "memory", "bedrock", "utils")

foreach ($dir in $lambdaDirs) {
    if (Test-Path $dir) {
        Write-Host "🔨 Building $dir..." -ForegroundColor Yellow
        Set-Location $dir
        
        # Install function-specific dependencies
        if (Test-Path "package.json") {
            npm install --production
        }
        
        # Compile TypeScript if tsconfig exists
        if (Test-Path "tsconfig.json") {
            npx tsc
        }
        
        Set-Location ..
        Write-Host "✅ $dir built successfully" -ForegroundColor Green
    }
}

Write-Host "✅ All Lambda functions built successfully!" -ForegroundColor Green

# Create deployment packages
Write-Host "📦 Creating deployment packages..." -ForegroundColor Blue

foreach ($dir in $lambdaDirs) {
    if (Test-Path $dir) {
        Write-Host "📦 Packaging $dir..." -ForegroundColor Yellow
        Set-Location $dir
        
        # Create zip file for deployment
        $excludePatterns = @("*.ts", "tsconfig.json", "node_modules/.cache/*", "*.test.*", "*.spec.*")
        Compress-Archive -Path "." -DestinationPath "../$dir.zip" -Force
        
        Set-Location ..
        Write-Host "✅ $dir packaged as $dir.zip" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "🎉 All Lambda functions are ready for deployment!" -ForegroundColor Green
Write-Host ""
Write-Host "📦 Deployment packages created:" -ForegroundColor Blue
foreach ($dir in $lambdaDirs) {
    if (Test-Path "$dir.zip") {
        Write-Host "  • $dir.zip" -ForegroundColor Cyan
    }
}