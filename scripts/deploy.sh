#!/bin/bash

# DevOps KnowledgeOps Agent Deployment Script

set -e

echo "🚀 Starting DevOps KnowledgeOps Agent deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
print_status "Checking prerequisites..."

if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

if ! command -v npm &> /dev/null; then
    print_error "npm is not installed. Please install Node.js and npm first."
    exit 1
fi

if ! command -v cdk &> /dev/null; then
    print_error "AWS CDK is not installed. Installing..."
    npm install -g aws-cdk
fi

# Check AWS credentials
print_status "Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

# Get AWS account and region
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region || echo "us-east-1")

print_success "AWS Account: $AWS_ACCOUNT_ID"
print_success "AWS Region: $AWS_REGION"

# Install dependencies
print_status "Installing dependencies..."
npm install

# Build TypeScript
print_status "Building TypeScript..."
npm run build

# Bootstrap CDK (if needed)
print_status "Bootstrapping CDK..."
cdk bootstrap aws://$AWS_ACCOUNT_ID/$AWS_REGION

# Deploy infrastructure
print_status "Deploying infrastructure..."
cdk deploy --require-approval never

# Get stack outputs
print_status "Getting stack outputs..."
STACK_OUTPUTS=$(aws cloudformation describe-stacks --stack-name DevOpsKnowledgeOpsStack --query 'Stacks[0].Outputs' --output json)

API_URL=$(echo $STACK_OUTPUTS | jq -r '.[] | select(.OutputKey=="ApiGatewayUrl") | .OutputValue')
BUCKET_NAME=$(echo $STACK_OUTPUTS | jq -r '.[] | select(.OutputKey=="KnowledgeBucketName") | .OutputValue')
USER_POOL_ID=$(echo $STACK_OUTPUTS | jq -r '.[] | select(.OutputKey=="UserPoolId") | .OutputValue')

print_success "API Gateway URL: $API_URL"
print_success "Knowledge Bucket: $BUCKET_NAME"
print_success "User Pool ID: $USER_POOL_ID"

# Upload knowledge base content
print_status "Uploading knowledge base content..."
cd scripts
export KNOWLEDGE_BUCKET_NAME=$BUCKET_NAME
npm run upload-kb
cd ..

# Create demo user
print_status "Creating demo user..."
curl -X POST "$API_URL/auth" \
  -H "Content-Type: application/json" \
  -d '{"action":"create-demo-user"}' || print_warning "Demo user creation failed (may already exist)"

# Build frontend
print_status "Building frontend..."
cd frontend
npm install
export REACT_APP_API_URL=$API_URL
npm run build
cd ..

print_success "🎉 Deployment completed successfully!"
echo ""
echo "📋 Next Steps:"
echo "1. Set up Bedrock Agent (optional - mock responses work for demo):"
echo "   cd scripts && npm run setup-agent"
echo ""
echo "2. Start the frontend development server:"
echo "   cd frontend && npm start"
echo ""
echo "3. Or serve the built frontend:"
echo "   cd frontend && npx serve -s build"
echo ""
echo "🔗 API Endpoint: $API_URL"
echo "👤 Demo User: demo-user / DemoPass123!"
echo ""
echo "🚀 Your DevOps KnowledgeOps Agent is ready!"