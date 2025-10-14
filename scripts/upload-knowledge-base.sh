#!/bin/bash

set -e

echo "📚 Uploading Knowledge Base Documents to S3..."

# Configuration
REGION=${AWS_REGION:-us-east-1}
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
S3_BUCKET=${KNOWLEDGE_BUCKET_NAME:-"devops-knowledge-$ACCOUNT_ID-$REGION"}

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check if bucket exists
if ! aws s3 ls "s3://$S3_BUCKET" &> /dev/null; then
    print_warning "S3 bucket $S3_BUCKET not found. Creating it..."
    aws s3 mb "s3://$S3_BUCKET" --region $REGION
    print_status "Created S3 bucket: $S3_BUCKET"
fi

# Upload knowledge base documents
echo "📤 Uploading knowledge base documents..."

# Check if knowledge-base directory exists
if [ ! -d "knowledge-base" ]; then
    echo "❌ knowledge-base directory not found. Please run from project root."
    exit 1
fi

# Upload all documents with proper content types
aws s3 sync knowledge-base/ "s3://$S3_BUCKET/knowledge-base/" \
    --exclude "*.DS_Store" \
    --exclude "*.git*" \
    --content-type "text/markdown" \
    --metadata-directive REPLACE

print_status "Uploaded knowledge base documents to s3://$S3_BUCKET/knowledge-base/"

# List uploaded files
echo "📋 Uploaded files:"
aws s3 ls "s3://$S3_BUCKET/knowledge-base/" --recursive --human-readable

# If Knowledge Base ID is available, sync the data source
if [ -n "$KNOWLEDGE_BASE_ID" ] && [ -n "$DATA_SOURCE_ID" ]; then
    echo "🔄 Starting Knowledge Base ingestion job..."
    
    JOB_RESPONSE=$(aws bedrock-agent start-ingestion-job \
        --knowledge-base-id $KNOWLEDGE_BASE_ID \
        --data-source-id $DATA_SOURCE_ID \
        --region $REGION)
    
    JOB_ID=$(echo $JOB_RESPONSE | jq -r '.ingestionJob.ingestionJobId')
    print_status "Started ingestion job: $JOB_ID"
    
    echo "⏳ Waiting for ingestion to complete..."
    while true; do
        JOB_STATUS=$(aws bedrock-agent get-ingestion-job \
            --knowledge-base-id $KNOWLEDGE_BASE_ID \
            --data-source-id $DATA_SOURCE_ID \
            --ingestion-job-id $JOB_ID \
            --region $REGION \
            --query 'ingestionJob.status' \
            --output text)
        
        echo "Ingestion status: $JOB_STATUS"
        
        if [ "$JOB_STATUS" = "COMPLETE" ]; then
            print_status "Knowledge base ingestion completed successfully!"
            break
        elif [ "$JOB_STATUS" = "FAILED" ]; then
            echo "❌ Knowledge base ingestion failed"
            exit 1
        fi
        
        sleep 30
    done
else
    print_warning "Knowledge Base ID or Data Source ID not set. Please run sync manually:"
    echo "aws bedrock-agent start-ingestion-job --knowledge-base-id <KB_ID> --data-source-id <DS_ID> --region $REGION"
fi

echo ""
echo "🎉 Knowledge Base Upload Complete!"
echo ""
echo "📊 Summary:"
echo "==========="
echo "S3 Bucket: $S3_BUCKET"
echo "Documents uploaded to: s3://$S3_BUCKET/knowledge-base/"
echo ""
echo "💡 Your agent now has access to:"
echo "- AWS EKS troubleshooting guides"
echo "- Terraform best practices"
echo "- CI/CD pipeline templates"
echo "- Security implementation guides"
echo "- Monitoring and observability setups"
echo ""
echo "🚀 Ready to answer DevOps questions with real knowledge!"