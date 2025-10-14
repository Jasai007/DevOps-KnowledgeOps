#!/bin/bash

set -e

echo "🚀 Setting up S3-based Vector Store for DevOps KnowledgeOps..."

# Configuration
REGION=${AWS_REGION:-us-east-1}
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
S3_BUCKET="devops-knowledge-$ACCOUNT_ID-$REGION"

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
print_status "Account ID: $ACCOUNT_ID"
print_status "Region: $REGION"
print_status "S3 Bucket: $S3_BUCKET"

# Check if Bedrock is available in region
echo "🔍 Checking Bedrock availability in $REGION..."
if ! aws bedrock list-foundation-models --region $REGION &> /dev/null; then
    print_error "Bedrock not available in region $REGION"
    print_warning "Try using us-east-1 or us-west-2"
    exit 1
fi

print_status "Bedrock available in $REGION"

# Check model access
echo "🔍 Checking Titan embedding model access..."
TITAN_MODELS=$(aws bedrock list-foundation-models --region $REGION --query 'modelSummaries[?contains(modelId, `titan-embed`)].modelId' --output text)

if [ -z "$TITAN_MODELS" ]; then
    print_warning "Titan embedding models not accessible. Please request model access in Bedrock console."
else
    print_status "Titan embedding models available: $TITAN_MODELS"
fi

# Create or verify S3 bucket
echo "📦 Setting up S3 bucket for vector storage..."

if aws s3 ls "s3://$S3_BUCKET" &> /dev/null; then
    print_warning "S3 bucket '$S3_BUCKET' already exists"
else
    aws s3 mb "s3://$S3_BUCKET" --region $REGION
    print_status "Created S3 bucket: $S3_BUCKET"
fi

# Create folder structure
echo "📁 Creating S3 folder structure..."
aws s3api put-object --bucket $S3_BUCKET --key vectors/ --region $REGION
aws s3api put-object --bucket $S3_BUCKET --key knowledge-base/ --region $REGION
aws s3api put-object --bucket $S3_BUCKET --key index/ --region $REGION

print_status "Created S3 folder structure"

# Create IAM role for S3 vector store
echo "🔐 Creating IAM role for S3 Vector Store..."

ROLE_NAME="S3VectorStoreRole-$REGION"
ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME"

# Check if role exists
if aws iam get-role --role-name $ROLE_NAME &> /dev/null; then
    print_warning "IAM role '$ROLE_NAME' already exists"
else
    # Create trust policy
    cat > /tmp/s3-vector-trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    "lambda.amazonaws.com",
                    "bedrock.amazonaws.com"
                ]
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

    # Create role
    aws iam create-role \
        --role-name $ROLE_NAME \
        --assume-role-policy-document file:///tmp/s3-vector-trust-policy.json \
        --region $REGION

    # Create and attach policy
    cat > /tmp/s3-vector-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
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
            "Resource": [
                "arn:aws:bedrock:$REGION::foundation-model/amazon.titan-embed-text-v2:0",
                "arn:aws:bedrock:$REGION::foundation-model/amazon.titan-embed-text-v1"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        }
    ]
}
EOF

    aws iam put-role-policy \
        --role-name $ROLE_NAME \
        --policy-name S3VectorStorePolicy \
        --policy-document file:///tmp/s3-vector-policy.json

    print_status "Created IAM role: $ROLE_ARN"
    
    # Wait for role to propagate
    sleep 10
fi

# Upload sample configuration
echo "📝 Creating S3 vector store configuration..."

cat > /tmp/s3-vector-config.json << EOF
{
    "name": "DevOpsKnowledgeBase-S3",
    "description": "S3-based vector storage for DevOps knowledge",
    "bucketName": "$S3_BUCKET",
    "vectorPrefix": "vectors/",
    "documentsPrefix": "knowledge-base/",
    "indexPrefix": "index/",
    "embeddingModel": "amazon.titan-embed-text-v2:0",
    "dimensions": 1024,
    "region": "$REGION",
    "chunkSize": 1000,
    "chunkOverlap": 200,
    "searchConfiguration": {
        "maxResults": 10,
        "similarityThreshold": 0.7,
        "searchAlgorithm": "cosine"
    },
    "createdAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "roleArn": "$ROLE_ARN"
}
EOF

aws s3 cp /tmp/s3-vector-config.json "s3://$S3_BUCKET/config/vector-store-config.json" --region $REGION

print_status "Uploaded vector store configuration"

# Create a simple test document
echo "📄 Creating test document..."

cat > /tmp/test-document.md << EOF
# DevOps Best Practices

## Infrastructure as Code
Use Infrastructure as Code (IaC) tools like Terraform or CloudFormation to manage your infrastructure. This ensures consistency, version control, and repeatability.

## Continuous Integration/Continuous Deployment
Implement CI/CD pipelines to automate testing and deployment. This reduces manual errors and speeds up delivery.

## Monitoring and Observability
Set up comprehensive monitoring using tools like Prometheus, Grafana, and CloudWatch. Monitor both infrastructure and application metrics.

## Security Best Practices
- Use least privilege access
- Implement secrets management
- Regular security scanning
- Network segmentation
EOF

aws s3 cp /tmp/test-document.md "s3://$S3_BUCKET/knowledge-base/test-document.md" --region $REGION

print_status "Uploaded test document"

# Output configuration
echo ""
echo "🎉 S3 Vector Store Setup Complete!"
echo ""
echo "📋 Configuration Details:"
echo "========================"
echo "S3 Bucket: $S3_BUCKET"
echo "IAM Role: $ROLE_ARN"
echo "Region: $REGION"
echo "Vector Prefix: vectors/"
echo "Documents Prefix: knowledge-base/"
echo "Index Prefix: index/"
echo ""
echo "🔧 Environment Variables:"
echo "========================="
echo "export KNOWLEDGE_BUCKET_NAME=$S3_BUCKET"
echo "export S3_VECTOR_STORE_ROLE_ARN=$ROLE_ARN"
echo "export AWS_REGION=$REGION"
echo ""
echo "💡 Next Steps:"
echo "=============="
echo "1. Set the environment variables above"
echo "2. Upload your knowledge base documents to s3://$S3_BUCKET/knowledge-base/"
echo "3. Run the vector processing script to create embeddings"
echo "4. Test the vector search functionality"
echo ""

# Save configuration to file
cat > s3-vector-config.env << EOF
# S3 Vector Store Configuration
export KNOWLEDGE_BUCKET_NAME=$S3_BUCKET
export S3_VECTOR_STORE_ROLE_ARN=$ROLE_ARN
export AWS_REGION=$REGION
export EMBEDDING_MODEL=amazon.titan-embed-text-v2:0
export VECTOR_DIMENSIONS=1024
EOF

print_status "Configuration saved to s3-vector-config.env"

# Clean up temporary files
rm -f /tmp/s3-vector-trust-policy.json /tmp/s3-vector-policy.json /tmp/s3-vector-config.json /tmp/test-document.md

echo ""
echo "🚀 S3 Vector Store is ready!"
echo ""
echo "💰 Cost Benefits:"
echo "================="
echo "- No OpenSearch Serverless charges (~$0.24/OCU-hour saved)"
echo "- Only S3 storage costs (~$0.023/GB/month)"
echo "- Pay-per-use Bedrock embedding calls"
echo "- Estimated monthly cost: $5-15 for typical usage"
echo ""
echo "🔍 To test the setup:"
echo "===================="
echo "1. Load the configuration: source s3-vector-config.env"
echo "2. Upload documents: ./scripts/upload-knowledge-base.sh"
echo "3. Process documents: ./scripts/process-s3-vectors.sh"
echo "4. Test search: ./scripts/test-s3-vector-search.sh"