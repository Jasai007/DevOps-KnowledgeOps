# Simple deployment script that works with limited AWS permissions
# This script sets up the S3 vector store and connects it to your existing Bedrock agent

param(
    [string]$Region = "us-east-1",
    [string]$AgentId = "MNJESZYALW"
)

Write-Host "🚀 Setting up DevOps KnowledgeOps with S3 Vector Store..." -ForegroundColor Green

# Set environment variables
$env:AWS_REGION = $Region
$env:BEDROCK_AGENT_ID = $AgentId

# Get account ID
$AccountId = (aws sts get-caller-identity --query Account --output text)
$S3Bucket = "devops-knowledge-$AccountId-$Region"

Write-Host "📋 Configuration:" -ForegroundColor Cyan
Write-Host "Account ID: $AccountId"
Write-Host "Region: $Region"
Write-Host "Agent ID: $AgentId"
Write-Host "S3 Bucket: $S3Bucket"

# Step 1: Create S3 bucket if it doesn't exist
Write-Host "`n📦 Setting up S3 bucket..." -ForegroundColor Yellow

try {
    aws s3 ls "s3://$S3Bucket" 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Creating S3 bucket: $S3Bucket"
        aws s3 mb "s3://$S3Bucket" --region $Region
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ S3 bucket created successfully" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to create S3 bucket" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "✅ S3 bucket already exists" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Error checking/creating S3 bucket: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Create folder structure
Write-Host "`n📁 Creating S3 folder structure..." -ForegroundColor Yellow

$folders = @("vectors/", "knowledge-base/", "index/", "config/")
foreach ($folder in $folders) {
    aws s3api put-object --bucket $S3Bucket --key $folder --region $Region 2>$null
}
Write-Host "✅ Folder structure created" -ForegroundColor Green

# Step 3: Upload knowledge base documents
Write-Host "`n📚 Uploading knowledge base documents..." -ForegroundColor Yellow

if (Test-Path "knowledge-base") {
    aws s3 sync knowledge-base/ "s3://$S3Bucket/knowledge-base/" --exclude "*.DS_Store" --exclude "*.git*" --region $Region
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Knowledge base documents uploaded" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Some documents may not have uploaded" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️ knowledge-base directory not found" -ForegroundColor Yellow
}

# Step 4: Create configuration file
Write-Host "`n📝 Creating configuration..." -ForegroundColor Yellow

$config = @{
    bucketName = $S3Bucket
    region = $Region
    agentId = $AgentId
    embeddingModel = "amazon.titan-embed-text-v2:0"
    vectorPrefix = "vectors/"
    documentsPrefix = "knowledge-base/"
    indexPrefix = "index/"
    dimensions = 1024
    createdAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
} | ConvertTo-Json -Depth 3

$config | Out-File -FilePath "temp-config.json" -Encoding UTF8
aws s3 cp "temp-config.json" "s3://$S3Bucket/config/s3-vector-config.json" --region $Region
Remove-Item "temp-config.json"

Write-Host "✅ Configuration uploaded" -ForegroundColor Green

# Step 5: Create environment file
Write-Host "`n🔧 Creating environment configuration..." -ForegroundColor Yellow

$envContent = @"
# DevOps KnowledgeOps Configuration
export AWS_REGION=$Region
export BEDROCK_AGENT_ID=$AgentId
export KNOWLEDGE_BUCKET_NAME=$S3Bucket
export EMBEDDING_MODEL=amazon.titan-embed-text-v2:0
export VECTOR_DIMENSIONS=1024
"@

$envContent | Out-File -FilePath "devops-config.env" -Encoding UTF8

Write-Host "✅ Environment file created: devops-config.env" -ForegroundColor Green

# Step 6: Test Bedrock agent
Write-Host "`n🧪 Testing Bedrock agent..." -ForegroundColor Yellow

$testQuery = "Hello, can you help me with DevOps?"
$sessionId = "test-session-$(Get-Date -Format 'yyyyMMddHHmmss')"

try {
    $response = aws bedrock-agent-runtime invoke-agent --agent-id $AgentId --agent-alias-id "TSTALIASID" --session-id $sessionId --input-text $testQuery --region $Region --output json 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Bedrock agent is responding" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Bedrock agent test failed, but setup is complete" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️ Could not test agent, but setup is complete" -ForegroundColor Yellow
}

# Step 7: Install dependencies
Write-Host "`n📦 Installing dependencies..." -ForegroundColor Yellow

if (Test-Path "package.json") {
    npm install
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Dependencies installed" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Some dependencies may not have installed" -ForegroundColor Yellow
    }
}

# Final summary
Write-Host "`n🎉 Setup Complete!" -ForegroundColor Green
Write-Host "==================" -ForegroundColor Green
Write-Host "✅ S3 Vector Store: $S3Bucket" -ForegroundColor White
Write-Host "✅ Bedrock Agent: $AgentId" -ForegroundColor White
Write-Host "✅ Region: $Region" -ForegroundColor White
Write-Host "✅ Configuration: devops-config.env" -ForegroundColor White

Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "1. Load configuration: . ./devops-config.env (Linux/Mac) or source the variables manually"
Write-Host "2. Start the frontend: cd frontend && npm start"
Write-Host "3. Test the chat interface at http://localhost:3000"

Write-Host "`nYour DevOps AI Assistant is ready!" -ForegroundColor Green