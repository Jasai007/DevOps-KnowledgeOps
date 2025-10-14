# Simple deployment script for DevOps KnowledgeOps
param(
    [string]$Region = "us-east-1",
    [string]$AgentId = "MNJESZYALW"
)

Write-Host "Setting up DevOps KnowledgeOps with S3 Vector Store..." -ForegroundColor Green

# Set environment variables
$env:AWS_REGION = $Region
$env:BEDROCK_AGENT_ID = $AgentId

# Get account ID
$AccountId = (aws sts get-caller-identity --query Account --output text)
$S3Bucket = "devops-knowledge-$AccountId-$Region"

Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "Account ID: $AccountId"
Write-Host "Region: $Region"
Write-Host "Agent ID: $AgentId"
Write-Host "S3 Bucket: $S3Bucket"

# Step 1: Create S3 bucket if it doesn't exist
Write-Host "`nSetting up S3 bucket..." -ForegroundColor Yellow

try {
    aws s3 ls "s3://$S3Bucket" 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Creating S3 bucket: $S3Bucket"
        aws s3 mb "s3://$S3Bucket" --region $Region
        if ($LASTEXITCODE -eq 0) {
            Write-Host "SUCCESS: S3 bucket created" -ForegroundColor Green
        } else {
            Write-Host "ERROR: Failed to create S3 bucket" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "SUCCESS: S3 bucket already exists" -ForegroundColor Green
    }
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Create folder structure
Write-Host "`nCreating S3 folder structure..." -ForegroundColor Yellow

$folders = @("vectors/", "knowledge-base/", "index/", "config/")
foreach ($folder in $folders) {
    aws s3api put-object --bucket $S3Bucket --key $folder --region $Region 2>$null
}
Write-Host "SUCCESS: Folder structure created" -ForegroundColor Green

# Step 3: Upload knowledge base documents
Write-Host "`nUploading knowledge base documents..." -ForegroundColor Yellow

if (Test-Path "knowledge-base") {
    aws s3 sync knowledge-base/ "s3://$S3Bucket/knowledge-base/" --exclude "*.DS_Store" --exclude "*.git*" --region $Region
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUCCESS: Knowledge base documents uploaded" -ForegroundColor Green
    } else {
        Write-Host "WARNING: Some documents may not have uploaded" -ForegroundColor Yellow
    }
} else {
    Write-Host "WARNING: knowledge-base directory not found" -ForegroundColor Yellow
}

# Step 4: Create environment file
Write-Host "`nCreating environment configuration..." -ForegroundColor Yellow

$envContent = @"
# DevOps KnowledgeOps Configuration
AWS_REGION=$Region
BEDROCK_AGENT_ID=$AgentId
KNOWLEDGE_BUCKET_NAME=$S3Bucket
EMBEDDING_MODEL=amazon.titan-embed-text-v2:0
VECTOR_DIMENSIONS=1024
"@

$envContent | Out-File -FilePath "devops-config.env" -Encoding UTF8
Write-Host "SUCCESS: Environment file created: devops-config.env" -ForegroundColor Green

# Step 5: Test Bedrock agent
Write-Host "`nTesting Bedrock agent..." -ForegroundColor Yellow

$testQuery = "Hello, can you help me with DevOps?"
$sessionId = "test-session-$(Get-Date -Format 'yyyyMMddHHmmss')"

try {
    $response = aws bedrock-agent-runtime invoke-agent --agent-id $AgentId --agent-alias-id "TSTALIASID" --session-id $sessionId --input-text $testQuery --region $Region --output json 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUCCESS: Bedrock agent is responding" -ForegroundColor Green
    } else {
        Write-Host "WARNING: Bedrock agent test failed, but setup is complete" -ForegroundColor Yellow
    }
} catch {
    Write-Host "WARNING: Could not test agent, but setup is complete" -ForegroundColor Yellow
}

# Step 6: Install dependencies
Write-Host "`nInstalling dependencies..." -ForegroundColor Yellow

if (Test-Path "package.json") {
    npm install
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUCCESS: Dependencies installed" -ForegroundColor Green
    } else {
        Write-Host "WARNING: Some dependencies may not have installed" -ForegroundColor Yellow
    }
}

# Final summary
Write-Host "`nSetup Complete!" -ForegroundColor Green
Write-Host "==================" -ForegroundColor Green
Write-Host "S3 Vector Store: $S3Bucket" -ForegroundColor White
Write-Host "Bedrock Agent: $AgentId" -ForegroundColor White
Write-Host "Region: $Region" -ForegroundColor White
Write-Host "Configuration: devops-config.env" -ForegroundColor White

Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "1. Install frontend dependencies: cd frontend && npm install"
Write-Host "2. Start the frontend: npm start"
Write-Host "3. Test the chat interface at http://localhost:3000"

Write-Host "`nYour DevOps AI Assistant is ready!" -ForegroundColor Green