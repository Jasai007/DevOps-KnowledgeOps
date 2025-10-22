#!/bin/bash

# DevOps KnowledgeOps Agent - Production Deployment Script
# Deploys backend (Express.js) to Elastic Beanstalk and frontend to S3

set -e

echo "🚀 Starting DevOps KnowledgeOps Agent Production Deployment..."

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

if ! command -v eb &> /dev/null; then
    print_error "EB CLI is not installed. Please install it first."
    exit 1
fi

if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed. Please install it first."
    exit 1
fi

if ! command -v npm &> /dev/null; then
    print_error "npm is not installed. Please install Node.js and npm first."
    exit 1
fi

if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first."
    exit 1
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

# Set application name
APP_NAME="devops-knowledgeops-agent"
ENV_NAME="devops-knowledgeops-prod"

# Backend deployment
print_status "Deploying backend to Elastic Beanstalk..."

# Create .ebextensions directory if it doesn't exist
mkdir -p backend/.ebextensions

# Create EB configuration
cat > backend/.ebextensions/environment.config << EOF
option_settings:
  aws:elasticbeanstalk:application:environment:
    NODE_ENV: production
    PORT: 8080
    AWS_REGION: $AWS_REGION
  aws:elasticbeanstalk:environment:proxy:staticfiles:
    /static: static
  aws:autoscaling:launchconfiguration:
    InstanceType: t3.micro
    IamInstanceProfile: aws-elasticbeanstalk-ec2-role
EOF

# Create package.json for EB if it doesn't exist
if [ ! -f backend/package.json ]; then
    cat > backend/package.json << EOF
{
  "name": "devops-knowledgeops-backend",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "uuid": "^9.0.1"
  }
}
EOF
fi

# Install backend dependencies
cd backend
npm install
cd ..

# Initialize EB application if it doesn't exist
if ! eb list | grep -q "$APP_NAME"; then
    print_status "Creating Elastic Beanstalk application..."
    eb init $APP_NAME --platform "Node.js 18" --region $AWS_REGION
else
    print_status "Elastic Beanstalk application already exists."
fi

# Create environment if it doesn't exist
if ! eb list | grep -q "$ENV_NAME"; then
    print_status "Creating production environment..."
    eb create $ENV_NAME --platform "Node.js 18" --region $AWS_REGION --instance-type t3.micro
else
    print_status "Production environment already exists. Deploying updates..."
    eb deploy $ENV_NAME
fi

# Get the backend URL
BACKEND_URL=$(eb status $ENV_NAME | grep "CNAME" | awk '{print $2}')

print_success "Backend deployed to: $BACKEND_URL"

# Frontend deployment
print_status "Building and deploying frontend to S3..."

# Build frontend
cd frontend
npm install
export REACT_APP_API_URL="http://$BACKEND_URL"
npm run build
cd ..

# Create S3 bucket for frontend
BUCKET_NAME="devops-knowledgeops-frontend-$AWS_ACCOUNT_ID"

if ! aws s3 ls "s3://$BUCKET_NAME" 2>&1 | grep -q 'NoSuchBucket'; then
    print_status "Creating S3 bucket for frontend..."
    aws s3 mb "s3://$BUCKET_NAME" --region $AWS_REGION
    aws s3 website "s3://$BUCKET_NAME" --index-document index.html --error-document index.html
fi

# Upload frontend build to S3
print_status "Uploading frontend to S3..."
aws s3 sync frontend/build "s3://$BUCKET_NAME" --delete

# Make bucket public for static website hosting
aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy "{
  \"Version\": \"2012-10-17\",
  \"Statement\": [
    {
      \"Sid\": \"PublicReadGetObject\",
      \"Effect\": \"Allow\",
      \"Principal\": \"*\",
      \"Action\": \"s3:GetObject\",
      \"Resource\": \"arn:aws:s3:::$BUCKET_NAME/*\"
    }
  ]
}"

FRONTEND_URL="http://$BUCKET_NAME.s3-website-$AWS_REGION.amazonaws.com"

print_success "Frontend deployed to: $FRONTEND_URL"

print_success "🎉 Production deployment completed successfully!"
echo ""
echo "📋 Deployment Summary:"
echo "Backend API: $BACKEND_URL"
echo "Frontend App: $"
echo ""
echo "🔗 Test your application:"
echo "curl $BACKEND_URL/health"
echo ""
echo "🚀 Your DevOps KnowledgeOps Agent is now live in production!"
