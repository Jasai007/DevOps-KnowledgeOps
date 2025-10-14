# PowerShell script for Windows users
# Amazon Bedrock Agent Setup for DevOps KnowledgeOps

param(
    [string]$Region = "us-east-1"
)

Write-Host "🚀 Setting up Amazon Bedrock Agent for DevOps KnowledgeOps..." -ForegroundColor Green

# Configuration
$AgentName = "DevOpsKnowledgeOpsAgent"
$KBName = "DevOpsKnowledgeBase"
$CollectionName = "devops-knowledge-collection"

# Check if AWS CLI is configured
try {
    $CallerIdentity = aws sts get-caller-identity --output json | ConvertFrom-Json
    $AccountId = $CallerIdentity.Account
    Write-Host "✅ AWS CLI configured successfully" -ForegroundColor Green
    Write-Host "Account ID: $AccountId" -ForegroundColor Cyan
}
catch {
    Write-Host "❌ AWS CLI not configured. Please run 'aws configure' first." -ForegroundColor Red
    exit 1
}

# Check if Bedrock is available in region
Write-Host "🔍 Checking Bedrock availability in $Region..." -ForegroundColor Yellow
try {
    aws bedrock list-foundation-models --region $Region --output json | Out-Null
    Write-Host "✅ Bedrock available in $Region" -ForegroundColor Green
}
catch {
    Write-Host "❌ Bedrock not available in region $Region" -ForegroundColor Red
    Write-Host "⚠️  Try using us-east-1 or us-west-2" -ForegroundColor Yellow
    exit 1
}

# List available models
Write-Host "📋 Available foundation models:" -ForegroundColor Cyan
aws bedrock list-foundation-models --region $Region --query 'modelSummaries[?contains(modelId, `claude`) || contains(modelId, `titan`)].{ModelId:modelId,Provider:providerName}' --output table

# Create OpenSearch Serverless collection
Write-Host "🔍 Creating OpenSearch Serverless collection..." -ForegroundColor Yellow

# Check if collection already exists
$ExistingCollection = aws opensearchserverless list-collections --region $Region --query "collectionSummaries[?name=='$CollectionName'].id" --output text 2>$null

if ($ExistingCollection) {
    Write-Host "⚠️  OpenSearch collection '$CollectionName' already exists" -ForegroundColor Yellow
    $CollectionId = $ExistingCollection
}
else {
    # Create collection
    $CollectionResponse = aws opensearchserverless create-collection --name $CollectionName --type VECTORSEARCH --description "DevOps Knowledge Base Vector Store" --region $Region --output json | ConvertFrom-Json
    $CollectionId = $CollectionResponse.createCollectionDetail.id
    Write-Host "✅ Created OpenSearch collection: $CollectionId" -ForegroundColor Green
    
    # Wait for collection to be active
    Write-Host "⏳ Waiting for collection to be active..." -ForegroundColor Yellow
    do {
        Start-Sleep -Seconds 10
        $Status = aws opensearchserverless list-collections --region $Region --query "collectionSummaries[?name=='$CollectionName'].status" --output text
        Write-Host "Collection status: $Status" -ForegroundColor Cyan
    } while ($Status -ne "ACTIVE")
}

Write-Host "✅ OpenSearch collection is ready: $CollectionId" -ForegroundColor Green

# Create IAM role for Knowledge Base
Write-Host "🔐 Creating IAM role for Knowledge Base..." -ForegroundColor Yellow

$KBRoleName = "BedrockKnowledgeBaseRole-$CollectionName"
$KBRoleArn = "arn:aws:iam::${AccountId}:role/$KBRoleName"

# Check if role exists
try {
    aws iam get-role --role-name $KBRoleName 2>$null | Out-Null
    Write-Host "⚠️  IAM role '$KBRoleName' already exists" -ForegroundColor Yellow
}
catch {
    # Create trust policy
    $TrustPolicy = @{
        Version = "2012-10-17"
        Statement = @(
            @{
                Effect = "Allow"
                Principal = @{
                    Service = "bedrock.amazonaws.com"
                }
                Action = "sts:AssumeRole"
            }
        )
    } | ConvertTo-Json -Depth 10

    $TrustPolicy | Out-File -FilePath "kb-trust-policy.json" -Encoding utf8

    # Create role
    aws iam create-role --role-name $KBRoleName --assume-role-policy-document file://kb-trust-policy.json --region $Region

    # Create and attach policy
    $KBPolicy = @{
        Version = "2012-10-17"
        Statement = @(
            @{
                Effect = "Allow"
                Action = @("aoss:APIAccessAll")
                Resource = "arn:aws:aoss:${Region}:${AccountId}:collection/$CollectionId"
            },
            @{
                Effect = "Allow"
                Action = @("s3:GetObject", "s3:ListBucket")
                Resource = @(
                    "arn:aws:s3:::devops-knowledge-$AccountId-$Region",
                    "arn:aws:s3:::devops-knowledge-$AccountId-$Region/*"
                )
            },
            @{
                Effect = "Allow"
                Action = @("bedrock:InvokeModel")
                Resource = "arn:aws:bedrock:${Region}::foundation-model/amazon.titan-embed-text-v2:0"
            }
        )
    } | ConvertTo-Json -Depth 10

    $KBPolicy | Out-File -FilePath "kb-policy.json" -Encoding utf8

    aws iam put-role-policy --role-name $KBRoleName --policy-name KnowledgeBasePolicy --policy-document file://kb-policy.json

    Write-Host "✅ Created IAM role: $KBRoleArn" -ForegroundColor Green
    
    # Wait for role to propagate
    Start-Sleep -Seconds 10
}

# Create Knowledge Base
Write-Host "📚 Creating Bedrock Knowledge Base..." -ForegroundColor Yellow

# Check if knowledge base exists
$ExistingKB = aws bedrock-agent list-knowledge-bases --region $Region --query "knowledgeBaseSummaries[?name=='$KBName'].knowledgeBaseId" --output text 2>$null

if ($ExistingKB) {
    Write-Host "⚠️  Knowledge Base '$KBName' already exists" -ForegroundColor Yellow
    $KBId = $ExistingKB
}
else {
    # Create knowledge base configuration
    $KBConfig = @{
        name = $KBName
        description = "Comprehensive DevOps documentation and best practices"
        roleArn = $KBRoleArn
        knowledgeBaseConfiguration = @{
            type = "VECTOR"
            vectorKnowledgeBaseConfiguration = @{
                embeddingModelArn = "arn:aws:bedrock:${Region}::foundation-model/amazon.titan-embed-text-v2:0"
                embeddingModelConfiguration = @{
                    bedrockEmbeddingModelConfiguration = @{
                        dimensions = 1024
                    }
                }
            }
        }
        storageConfiguration = @{
            type = "OPENSEARCH_SERVERLESS"
            opensearchServerlessConfiguration = @{
                collectionArn = "arn:aws:aoss:${Region}:${AccountId}:collection/$CollectionId"
                vectorIndexName = "devops-knowledge-index"
                fieldMapping = @{
                    vectorField = "vector"
                    textField = "text"
                    metadataField = "metadata"
                }
            }
        }
    } | ConvertTo-Json -Depth 10

    $KBConfig | Out-File -FilePath "kb-config.json" -Encoding utf8

    $KBResponse = aws bedrock-agent create-knowledge-base --region $Region --cli-input-json file://kb-config.json --output json | ConvertFrom-Json
    $KBId = $KBResponse.knowledgeBase.knowledgeBaseId
    Write-Host "✅ Created Knowledge Base: $KBId" -ForegroundColor Green
}

# Output configuration
Write-Host ""
Write-Host "🎉 Bedrock Agent Setup Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Configuration Details:" -ForegroundColor Cyan
Write-Host "========================"
Write-Host "Knowledge Base ID: $KBId"
Write-Host "Collection ID: $CollectionId"
Write-Host "S3 Bucket: devops-knowledge-$AccountId-$Region"
Write-Host ""
Write-Host "🔧 Environment Variables:" -ForegroundColor Cyan
Write-Host "========================="
Write-Host "`$env:KNOWLEDGE_BASE_ID='$KBId'"
Write-Host "`$env:AWS_REGION='$Region'"
Write-Host ""
Write-Host "💡 Next Steps:" -ForegroundColor Cyan
Write-Host "=============="
Write-Host "1. Set the environment variables above"
Write-Host "2. Upload knowledge base documents: .\scripts\upload-knowledge-base.ps1"
Write-Host "3. Create the Bedrock Agent manually in AWS Console"
Write-Host "4. Test the agent with real queries"
Write-Host ""

# Save configuration to file
@"
# Bedrock Agent Configuration
`$env:KNOWLEDGE_BASE_ID='$KBId'
`$env:COLLECTION_ID='$CollectionId'
`$env:S3_BUCKET='devops-knowledge-$AccountId-$Region'
`$env:AWS_REGION='$Region'
"@ | Out-File -FilePath "bedrock-config.ps1" -Encoding utf8

Write-Host "✅ Configuration saved to bedrock-config.ps1" -ForegroundColor Green

# Clean up temporary files
Remove-Item -Path "kb-trust-policy.json", "kb-policy.json", "kb-config.json" -ErrorAction SilentlyContinue

Write-Host "🚀 Ready to configure Bedrock Agent in AWS Console!" -ForegroundColor Green