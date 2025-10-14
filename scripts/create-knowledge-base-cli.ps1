# PowerShell script to create Bedrock Knowledge Base using AWS CLI
# For DevOps KnowledgeOps Agent

param(
    [string]$Region = "us-east-1"
)

Write-Host "🚀 Creating Bedrock Knowledge Base using AWS CLI..." -ForegroundColor Green

# Configuration
$AccountId = "992382848863"
$KBName = "DevOpsKnowledgeBase"
$CollectionName = "devops-knowledge-collection"
$S3Bucket = "devops-knowledge-$AccountId-$Region"

# Colors for output
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }

# Step 1: Create OpenSearch Serverless Collection
Write-Host "📋 Step 1: Creating OpenSearch Serverless Collection..." -ForegroundColor Cyan

# Check if collection already exists
$ExistingCollection = aws opensearchserverless list-collections --region $Region --query "collectionSummaries[?name=='$CollectionName'].id" --output text 2>$null

if ($ExistingCollection -and $ExistingCollection -ne "None") {
    Write-Warning "OpenSearch collection '$CollectionName' already exists: $ExistingCollection"
    $CollectionId = $ExistingCollection
} else {
    # Create collection
    try {
        $CollectionResponse = aws opensearchserverless create-collection `
            --name $CollectionName `
            --type VECTORSEARCH `
            --description "DevOps Knowledge Base Vector Store" `
            --region $Region `
            --output json | ConvertFrom-Json
        
        $CollectionId = $CollectionResponse.createCollectionDetail.id
        Write-Success "Created OpenSearch collection: $CollectionId"
        
        # Wait for collection to be active
        Write-Host "⏳ Waiting for collection to be active..." -ForegroundColor Yellow
        do {
            Start-Sleep -Seconds 10
            $Status = aws opensearchserverless list-collections --region $Region --query "collectionSummaries[?name=='$CollectionName'].status" --output text
            Write-Host "Collection status: $Status" -ForegroundColor Cyan
        } while ($Status -ne "ACTIVE")
        
        Write-Success "Collection is now active"
    }
    catch {
        Write-Error "Failed to create OpenSearch collection: $_"
        exit 1
    }
}

# Step 2: Create IAM Role for Knowledge Base
Write-Host "📋 Step 2: Creating IAM Role for Knowledge Base..." -ForegroundColor Cyan

$KBRoleName = "BedrockKnowledgeBaseRole-DevOps"
$KBRoleArn = "arn:aws:iam::${AccountId}:role/$KBRoleName"

# Check if role exists
try {
    aws iam get-role --role-name $KBRoleName 2>$null | Out-Null
    Write-Warning "IAM role '$KBRoleName' already exists"
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
    aws iam create-role `
        --role-name $KBRoleName `
        --assume-role-policy-document file://kb-trust-policy.json `
        --region $Region

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
                    "arn:aws:s3:::$S3Bucket",
                    "arn:aws:s3:::$S3Bucket/*"
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

    aws iam put-role-policy `
        --role-name $KBRoleName `
        --policy-name KnowledgeBasePolicy `
        --policy-document file://kb-policy.json

    Write-Success "Created IAM role: $KBRoleArn"
    
    # Wait for role to propagate
    Start-Sleep -Seconds 10
}

# Step 3: Create Knowledge Base Configuration
Write-Host "📋 Step 3: Creating Knowledge Base..." -ForegroundColor Cyan

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

# Create knowledge base
try {
    $KBResponse = aws bedrock-agent create-knowledge-base `
        --region $Region `
        --cli-input-json file://kb-config.json `
        --output json | ConvertFrom-Json
    
    $KBId = $KBResponse.knowledgeBase.knowledgeBaseId
    Write-Success "Created Knowledge Base: $KBId"
}
catch {
    Write-Error "Failed to create knowledge base: $_"
    exit 1
}

# Step 4: Create Data Source
Write-Host "📋 Step 4: Creating Data Source..." -ForegroundColor Cyan

$DSConfig = @{
    knowledgeBaseId = $KBId
    name = "DevOpsDocuments"
    description = "DevOps documentation and best practices"
    dataSourceConfiguration = @{
        type = "S3"
        s3Configuration = @{
            bucketArn = "arn:aws:s3:::$S3Bucket"
            inclusionPrefixes = @("knowledge-base/")
        }
    }
    vectorIngestionConfiguration = @{
        chunkingConfiguration = @{
            chunkingStrategy = "FIXED_SIZE"
            fixedSizeChunkingConfiguration = @{
                maxTokens = 300
                overlapPercentage = 20
            }
        }
    }
} | ConvertTo-Json -Depth 10

$DSConfig | Out-File -FilePath "ds-config.json" -Encoding utf8

try {
    $DSResponse = aws bedrock-agent create-data-source `
        --region $Region `
        --cli-input-json file://ds-config.json `
        --output json | ConvertFrom-Json
    
    $DSId = $DSResponse.dataSource.dataSourceId
    Write-Success "Created Data Source: $DSId"
}
catch {
    Write-Error "Failed to create data source: $_"
    exit 1
}

# Step 5: Start Ingestion Job
Write-Host "📋 Step 5: Starting Knowledge Base Ingestion..." -ForegroundColor Cyan

try {
    $IngestionResponse = aws bedrock-agent start-ingestion-job `
        --knowledge-base-id $KBId `
        --data-source-id $DSId `
        --region $Region `
        --output json | ConvertFrom-Json
    
    $JobId = $IngestionResponse.ingestionJob.ingestionJobId
    Write-Success "Started ingestion job: $JobId"
    
    # Wait for ingestion to complete
    Write-Host "⏳ Waiting for ingestion to complete..." -ForegroundColor Yellow
    do {
        Start-Sleep -Seconds 30
        $JobStatus = aws bedrock-agent get-ingestion-job `
            --knowledge-base-id $KBId `
            --data-source-id $DSId `
            --ingestion-job-id $JobId `
            --region $Region `
            --query 'ingestionJob.status' `
            --output text
        
        Write-Host "Ingestion status: $JobStatus" -ForegroundColor Cyan
        
        if ($JobStatus -eq "FAILED") {
            Write-Error "Knowledge base ingestion failed"
            exit 1
        }
    } while ($JobStatus -ne "COMPLETE")
    
    Write-Success "Knowledge base ingestion completed successfully!"
}
catch {
    Write-Error "Failed to start ingestion job: $_"
    exit 1
}

# Output configuration
Write-Host ""
Write-Host "🎉 Knowledge Base Created Successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Configuration Details:" -ForegroundColor Cyan
Write-Host "========================"
Write-Host "Knowledge Base ID: $KBId"
Write-Host "Data Source ID: $DSId"
Write-Host "Collection ID: $CollectionId"
Write-Host "S3 Bucket: $S3Bucket"
Write-Host "IAM Role: $KBRoleArn"
Write-Host ""
Write-Host "🔧 Environment Variables:" -ForegroundColor Cyan
Write-Host "========================="
Write-Host "`$env:KNOWLEDGE_BASE_ID='$KBId'"
Write-Host "`$env:DATA_SOURCE_ID='$DSId'"
Write-Host "`$env:COLLECTION_ID='$CollectionId'"
Write-Host "`$env:S3_BUCKET='$S3Bucket'"
Write-Host "`$env:AWS_REGION='$Region'"
Write-Host ""

# Save configuration to file
$ConfigContent = @"
# Bedrock Knowledge Base Configuration
`$env:KNOWLEDGE_BASE_ID='$KBId'
`$env:DATA_SOURCE_ID='$DSId'
`$env:COLLECTION_ID='$CollectionId'
`$env:S3_BUCKET='$S3Bucket'
`$env:AWS_REGION='$Region'
"@

$ConfigContent | Out-File -FilePath "knowledge-base-config.ps1" -Encoding utf8

Write-Success "Configuration saved to knowledge-base-config.ps1"

# Clean up temporary files
Remove-Item -Path "kb-trust-policy.json", "kb-policy.json", "kb-config.json", "ds-config.json" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "💡 Next Steps:" -ForegroundColor Cyan
Write-Host "=============="
Write-Host "1. Use the Knowledge Base ID above in your Bedrock Agent"
Write-Host "2. Test retrieval: aws bedrock-agent-runtime retrieve --knowledge-base-id $KBId --retrieval-query `"Kubernetes troubleshooting`" --region $Region"
Write-Host "3. Add to your agent in the Bedrock Console"
Write-Host ""
Write-Host "🚀 Knowledge Base is ready for your DevOps Agent!" -ForegroundColor Green