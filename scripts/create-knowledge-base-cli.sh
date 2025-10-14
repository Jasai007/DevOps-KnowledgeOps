#!/bin/bash

set -e

echo "🚀 Creating Bedrock Knowledge Base using AWS CLI..."

# Configuration
REGION=${AWS_REGION:-us-east-1}
ACCOUNT_ID="992382848863"
KB_NAME="DevOpsKnowledgeBase"
COLLECTION_NAME="devops-knowledge-collection"
S3_BUCKET="devops-knowledge-$ACCOUNT_ID-$REGION"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${CYAN}📋 $1${NC}"; }

# Step 1: Create OpenSearch Serverless Collection
print_info "Step 1: Creating OpenSearch Serverless Collection..."

# Check if collection already exists
EXISTING_COLLECTION=$(aws opensearchserverless list-collections --region $REGION --query "collectionSummaries[?name=='$COLLECTION_NAME'].id" --output text 2>/dev/null || echo "")

if [ -n "$EXISTING_COLLECTION" ] && [ "$EXISTING_COLLECTION" != "None" ]; then
    print_warning "OpenSearch collection '$COLLECTION_NAME' already exists: $EXISTING_COLLECTION"
    COLLECTION_ID=$EXISTING_COLLECTION
else
    # Create collection
    COLLECTION_RESPONSE=$(aws opensearchserverless create-collection \
        --name $COLLECTION_NAME \
        --type VECTORSEARCH \
        --description "DevOps Knowledge Base Vector Store" \
        --region $REGION \
        --output json)
    
    COLLECTION_ID=$(echo $COLLECTION_RESPONSE | jq -r '.createCollectionDetail.id')
    print_success "Created OpenSearch collection: $COLLECTION_ID"
    
    # Wait for collection to be active
    echo "⏳ Waiting for collection to be active..."
    while true; do
        STATUS=$(aws opensearchserverless list-collections --region $REGION --query "collectionSummaries[?name=='$COLLECTION_NAME'].status" --output text)
        echo "Collection status: $STATUS"
        if [ "$STATUS" = "ACTIVE" ]; then
            break
        fi
        sleep 10
    done
    
    print_success "Collection is now active"
fi

# Step 2: Create IAM Role for Knowledge Base
print_info "Step 2: Creating IAM Role for Knowledge Base..."

KB_ROLE_NAME="BedrockKnowledgeBaseRole-DevOps"
KB_ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/$KB_ROLE_NAME"

# Check if role exists
if aws iam get-role --role-name $KB_ROLE_NAME &> /dev/null; then
    print_warning "IAM role '$KB_ROLE_NAME' already exists"
else
    # Create trust policy
    cat > /tmp/kb-trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "bedrock.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

    # Create role
    aws iam create-role \
        --role-name $KB_ROLE_NAME \
        --assume-role-policy-document file:///tmp/kb-trust-policy.json \
        --region $REGION

    # Create and attach policy
    cat > /tmp/kb-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "aoss:APIAccessAll"
            ],
            "Resource": "arn:aws:aoss:$REGION:$ACCOUNT_ID:collection/$COLLECTION_ID"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::$S3_BUCKET",
                "arn:aws:s3:::$S3_BUCKET/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "bedrock:InvokeModel"
            ],
            "Resource": "arn:aws:bedrock:$REGION::foundation-model/amazon.titan-embed-text-v2:0"
        }
    ]
}
EOF

    aws iam put-role-policy \
        --role-name $KB_ROLE_NAME \
        --policy-name KnowledgeBasePolicy \
        --policy-document file:///tmp/kb-policy.json

    print_success "Created IAM role: $KB_ROLE_ARN"
    
    # Wait for role to propagate
    sleep 10
fi

# Step 3: Create Knowledge Base
print_info "Step 3: Creating Knowledge Base..."

# Create knowledge base configuration
cat > /tmp/kb-config.json << EOF
{
    "name": "$KB_NAME",
    "description": "Comprehensive DevOps documentation and best practices",
    "roleArn": "$KB_ROLE_ARN",
    "knowledgeBaseConfiguration": {
        "type": "VECTOR",
        "vectorKnowledgeBaseConfiguration": {
            "embeddingModelArn": "arn:aws:bedrock:$REGION::foundation-model/amazon.titan-embed-text-v2:0",
            "embeddingModelConfiguration": {
                "bedrockEmbeddingModelConfiguration": {
                    "dimensions": 1024
                }
            }
        }
    },
    "storageConfiguration": {
        "type": "OPENSEARCH_SERVERLESS",
        "opensearchServerlessConfiguration": {
            "collectionArn": "arn:aws:aoss:$REGION:$ACCOUNT_ID:collection/$COLLECTION_ID",
            "vectorIndexName": "devops-knowledge-index",
            "fieldMapping": {
                "vectorField": "vector",
                "textField": "text",
                "metadataField": "metadata"
            }
        }
    }
}
EOF

KB_RESPONSE=$(aws bedrock-agent create-knowledge-base \
    --region $REGION \
    --cli-input-json file:///tmp/kb-config.json)

KB_ID=$(echo $KB_RESPONSE | jq -r '.knowledgeBase.knowledgeBaseId')
print_success "Created Knowledge Base: $KB_ID"

# Step 4: Create Data Source
print_info "Step 4: Creating Data Source..."

cat > /tmp/ds-config.json << EOF
{
    "knowledgeBaseId": "$KB_ID",
    "name": "DevOpsDocuments",
    "description": "DevOps documentation and best practices",
    "dataSourceConfiguration": {
        "type": "S3",
        "s3Configuration": {
            "bucketArn": "arn:aws:s3:::$S3_BUCKET",
            "inclusionPrefixes": ["knowledge-base/"]
        }
    },
    "vectorIngestionConfiguration": {
        "chunkingConfiguration": {
            "chunkingStrategy": "FIXED_SIZE",
            "fixedSizeChunkingConfiguration": {
                "maxTokens": 300,
                "overlapPercentage": 20
            }
        }
    }
}
EOF

DS_RESPONSE=$(aws bedrock-agent create-data-source \
    --region $REGION \
    --cli-input-json file:///tmp/ds-config.json)

DS_ID=$(echo $DS_RESPONSE | jq -r '.dataSource.dataSourceId')
print_success "Created Data Source: $DS_ID"

# Step 5: Start Ingestion Job
print_info "Step 5: Starting Knowledge Base Ingestion..."

INGESTION_RESPONSE=$(aws bedrock-agent start-ingestion-job \
    --knowledge-base-id $KB_ID \
    --data-source-id $DS_ID \
    --region $REGION)

JOB_ID=$(echo $INGESTION_RESPONSE | jq -r '.ingestionJob.ingestionJobId')
print_success "Started ingestion job: $JOB_ID"

# Wait for ingestion to complete
echo "⏳ Waiting for ingestion to complete..."
while true; do
    JOB_STATUS=$(aws bedrock-agent get-ingestion-job \
        --knowledge-base-id $KB_ID \
        --data-source-id $DS_ID \
        --ingestion-job-id $JOB_ID \
        --region $REGION \
        --query 'ingestionJob.status' \
        --output text)
    
    echo "Ingestion status: $JOB_STATUS"
    
    if [ "$JOB_STATUS" = "COMPLETE" ]; then
        print_success "Knowledge base ingestion completed successfully!"
        break
    elif [ "$JOB_STATUS" = "FAILED" ]; then
        print_error "Knowledge base ingestion failed"
        exit 1
    fi
    
    sleep 30
done

# Output configuration
echo ""
print_success "🎉 Knowledge Base Created Successfully!"
echo ""
echo "📋 Configuration Details:"
echo "========================"
echo "Knowledge Base ID: $KB_ID"
echo "Data Source ID: $DS_ID"
echo "Collection ID: $COLLECTION_ID"
echo "S3 Bucket: $S3_BUCKET"
echo "IAM Role: $KB_ROLE_ARN"
echo ""
echo "🔧 Environment Variables:"
echo "========================="
echo "export KNOWLEDGE_BASE_ID=$KB_ID"
echo "export DATA_SOURCE_ID=$DS_ID"
echo "export COLLECTION_ID=$COLLECTION_ID"
echo "export S3_BUCKET=$S3_BUCKET"
echo "export AWS_REGION=$REGION"
echo ""

# Save configuration to file
cat > knowledge-base-config.env << EOF
# Bedrock Knowledge Base Configuration
export KNOWLEDGE_BASE_ID=$KB_ID
export DATA_SOURCE_ID=$DS_ID
export COLLECTION_ID=$COLLECTION_ID
export S3_BUCKET=$S3_BUCKET
export AWS_REGION=$REGION
EOF

print_success "Configuration saved to knowledge-base-config.env"

# Clean up temporary files
rm -f /tmp/kb-trust-policy.json /tmp/kb-policy.json /tmp/kb-config.json /tmp/ds-config.json

echo ""
echo "💡 Next Steps:"
echo "=============="
echo "1. Use the Knowledge Base ID above in your Bedrock Agent"
echo "2. Test retrieval: aws bedrock-agent-runtime retrieve --knowledge-base-id $KB_ID --retrieval-query 'Kubernetes troubleshooting' --region $REGION"
echo "3. Add to your agent in the Bedrock Console"
echo ""
print_success "🚀 Knowledge Base is ready for your DevOps Agent!"