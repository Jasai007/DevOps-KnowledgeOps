#!/bin/bash

set -e

echo "🚀 Setting up Amazon Bedrock Agent for DevOps KnowledgeOps..."

# Configuration
REGION=${AWS_REGION:-us-east-1}
AGENT_NAME="DevOpsKnowledgeOpsAgent"
KB_NAME="DevOpsKnowledgeBase"
COLLECTION_NAME="devops-knowledge-collection"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

print_status "AWS CLI configured successfully"

# Get account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
print_status "Account ID: $ACCOUNT_ID"

# Check if Bedrock is available in region
echo "🔍 Checking Bedrock availability in $REGION..."
if ! aws bedrock list-foundation-models --region $REGION &> /dev/null; then
    print_error "Bedrock not available in region $REGION"
    print_warning "Try using us-east-1 or us-west-2"
    exit 1
fi

print_status "Bedrock available in $REGION"

# Check model access
echo "🔍 Checking model access..."
MODEL_ACCESS=$(aws bedrock get-model-invocation-logging-configuration --region $REGION 2>/dev/null || echo "not-configured")

# List available models
echo "📋 Available foundation models:"
aws bedrock list-foundation-models --region $REGION --query 'modelSummaries[?contains(modelId, `claude`) || contains(modelId, `titan`)].{ModelId:modelId,Provider:providerName}' --output table

# Create OpenSearch Serverless collection for vector storage
echo "🔍 Creating OpenSearch Serverless collection..."

# Check if collection already exists
EXISTING_COLLECTION=$(aws opensearchserverless list-collections --region $REGION --query "collectionSummaries[?name=='$COLLECTION_NAME'].id" --output text 2>/dev/null || echo "")

if [ -n "$EXISTING_COLLECTION" ]; then
    print_warning "OpenSearch collection '$COLLECTION_NAME' already exists"
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
    print_status "Created OpenSearch collection: $COLLECTION_ID"
    
    # Wait for collection to be active
    echo "⏳ Waiting for collection to be active..."
    while true; do
        STATUS=$(aws opensearchserverless list-collections --region $REGION --query "collectionSummaries[?name=='$COLLECTION_NAME'].status" --output text)
        if [ "$STATUS" = "ACTIVE" ]; then
            break
        fi
        echo "Collection status: $STATUS"
        sleep 10
    done
fi

print_status "OpenSearch collection is ready: $COLLECTION_ID"

# Create IAM role for Knowledge Base
echo "🔐 Creating IAM role for Knowledge Base..."

KB_ROLE_NAME="BedrockKnowledgeBaseRole-$COLLECTION_NAME"
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
                "arn:aws:s3:::devops-knowledge-$ACCOUNT_ID-$REGION",
                "arn:aws:s3:::devops-knowledge-$ACCOUNT_ID-$REGION/*"
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

    print_status "Created IAM role: $KB_ROLE_ARN"
    
    # Wait for role to propagate
    sleep 10
fi

# Create Knowledge Base
echo "📚 Creating Bedrock Knowledge Base..."

# Check if knowledge base exists
EXISTING_KB=$(aws bedrock-agent list-knowledge-bases --region $REGION --query "knowledgeBaseSummaries[?name=='$KB_NAME'].knowledgeBaseId" --output text 2>/dev/null || echo "")

if [ -n "$EXISTING_KB" ]; then
    print_warning "Knowledge Base '$KB_NAME' already exists"
    KB_ID=$EXISTING_KB
else
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
    print_status "Created Knowledge Base: $KB_ID"
fi

# Create Data Source for Knowledge Base
echo "📄 Creating Data Source..."

S3_BUCKET="devops-knowledge-$ACCOUNT_ID-$REGION"

# Check if data source exists
EXISTING_DS=$(aws bedrock-agent list-data-sources --knowledge-base-id $KB_ID --region $REGION --query "dataSourceSummaries[0].dataSourceId" --output text 2>/dev/null || echo "None")

if [ "$EXISTING_DS" != "None" ]; then
    print_warning "Data Source already exists: $EXISTING_DS"
    DS_ID=$EXISTING_DS
else
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
    }
}
EOF

    DS_RESPONSE=$(aws bedrock-agent create-data-source \
        --region $REGION \
        --cli-input-json file:///tmp/ds-config.json)
    
    DS_ID=$(echo $DS_RESPONSE | jq -r '.dataSource.dataSourceId')
    print_status "Created Data Source: $DS_ID"
fi

# Create Bedrock Agent
echo "🤖 Creating Bedrock Agent..."

# Check if agent exists
EXISTING_AGENT=$(aws bedrock-agent list-agents --region $REGION --query "agentSummaries[?agentName=='$AGENT_NAME'].agentId" --output text 2>/dev/null || echo "")

if [ -n "$EXISTING_AGENT" ]; then
    print_warning "Agent '$AGENT_NAME' already exists"
    AGENT_ID=$EXISTING_AGENT
else
    # Create agent
    AGENT_RESPONSE=$(aws bedrock-agent create-agent \
        --agent-name "$AGENT_NAME" \
        --description "Expert DevOps assistant providing comprehensive guidance and solutions" \
        --foundation-model "anthropic.claude-3-5-sonnet-20241022-v2:0" \
        --instruction "$(cat lambda/bedrock/agent-config.ts | grep -A 50 'instruction:' | sed -n '/`/,/`/p' | sed '1d;$d')" \
        --region $REGION)
    
    AGENT_ID=$(echo $AGENT_RESPONSE | jq -r '.agent.agentId')
    print_status "Created Agent: $AGENT_ID"
fi

# Associate Knowledge Base with Agent
echo "🔗 Associating Knowledge Base with Agent..."

aws bedrock-agent associate-agent-knowledge-base \
    --agent-id $AGENT_ID \
    --knowledge-base-id $KB_ID \
    --description "DevOps knowledge base for comprehensive guidance" \
    --knowledge-base-state ENABLED \
    --region $REGION 2>/dev/null || print_warning "Knowledge base may already be associated"

# Prepare Agent
echo "⚙️ Preparing Agent..."
aws bedrock-agent prepare-agent \
    --agent-id $AGENT_ID \
    --region $REGION

print_status "Agent prepared successfully"

# Create Agent Alias
echo "🏷️ Creating Agent Alias..."

ALIAS_RESPONSE=$(aws bedrock-agent create-agent-alias \
    --agent-id $AGENT_ID \
    --agent-alias-name "LIVE" \
    --description "Live version of DevOps Agent" \
    --region $REGION 2>/dev/null || echo '{"agentAlias":{"agentAliasId":"TSTALIASID"}}')

ALIAS_ID=$(echo $ALIAS_RESPONSE | jq -r '.agentAlias.agentAliasId')
print_status "Created Agent Alias: $ALIAS_ID"

# Output configuration
echo ""
echo "🎉 Bedrock Agent Setup Complete!"
echo ""
echo "📋 Configuration Details:"
echo "========================"
echo "Agent ID: $AGENT_ID"
echo "Agent Alias ID: $ALIAS_ID"
echo "Knowledge Base ID: $KB_ID"
echo "Data Source ID: $DS_ID"
echo "S3 Bucket: $S3_BUCKET"
echo ""
echo "🔧 Environment Variables:"
echo "========================="
echo "export BEDROCK_AGENT_ID=$AGENT_ID"
echo "export BEDROCK_AGENT_ALIAS_ID=$ALIAS_ID"
echo "export KNOWLEDGE_BASE_ID=$KB_ID"
echo ""
echo "💡 Next Steps:"
echo "=============="
echo "1. Set the environment variables above"
echo "2. Upload knowledge base documents: ./scripts/upload-knowledge-base.sh"
echo "3. Sync the data source to index documents"
echo "4. Test the agent with real queries"
echo ""

# Save configuration to file
cat > bedrock-config.env << EOF
# Bedrock Agent Configuration
export BEDROCK_AGENT_ID=$AGENT_ID
export BEDROCK_AGENT_ALIAS_ID=$ALIAS_ID
export KNOWLEDGE_BASE_ID=$KB_ID
export DATA_SOURCE_ID=$DS_ID
export S3_BUCKET=$S3_BUCKET
export AWS_REGION=$REGION
EOF

print_status "Configuration saved to bedrock-config.env"

# Clean up temporary files
rm -f /tmp/kb-trust-policy.json /tmp/kb-policy.json /tmp/kb-config.json /tmp/ds-config.json

echo "🚀 Ready to use real AI processing!"