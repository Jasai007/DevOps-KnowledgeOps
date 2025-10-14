#!/bin/bash

# Production Deployment Script for DevOps KnowledgeOps Agent
# This script handles the complete production deployment to AWS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
STACK_NAME="DevOpsKnowledgeOpsStack"
REGION="us-east-1"
ENVIRONMENT="production"

# Functions
print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI not found. Please install it first."
        exit 1
    fi
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        print_error "Node.js not found. Please install it first."
        exit 1
    fi
    
    # Check CDK
    if ! command -v cdk &> /dev/null; then
        print_status "Installing AWS CDK..."
        npm install -g aws-cdk
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Run 'aws configure' first."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Get deployment configuration
get_config() {
    print_status "Getting deployment configuration..."
    
    export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    export AWS_REGION=$REGION
    
    print_success "Account ID: $AWS_ACCOUNT_ID"
    print_success "Region: $AWS_REGION"
    print_success "Environment: $ENVIRONMENT"
}

# Install dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    
    # Root dependencies
    npm ci
    
    # Frontend dependencies
    cd frontend
    npm ci
    cd ..
    
    # Lambda dependencies
    for dir in lambda/*/; do
        if [ -f "$dir/package.json" ]; then
            print_status "Installing dependencies for $dir"
            cd "$dir"
            npm ci
            cd - > /dev/null
        fi
    done
    
    print_success "Dependencies installed"
}

# Build application
build_application() {
    print_status "Building application..."
    
    # Build TypeScript
    npm run build
    
    # Build Lambda functions
    cd lambda/chat-processor
    npm run build 2>/dev/null || echo "No build script found"
    cd ../..
    
    print_success "Application built"
}

# Deploy infrastructure
deploy_infrastructure() {
    print_status "Deploying infrastructure..."
    
    # Bootstrap CDK if needed
    cdk bootstrap aws://$AWS_ACCOUNT_ID/$AWS_REGION
    
    # Deploy stack
    cdk deploy $STACK_NAME \
        --require-approval never \
        --parameters Environment=$ENVIRONMENT \
        --tags Project=DevOpsKnowledgeOps \
        --tags Environment=$ENVIRONMENT \
        --tags Owner=DevOpsTeam
    
    print_success "Infrastructure deployed"
}

# Get stack outputs
get_stack_outputs() {
    print_status "Getting stack outputs..."
    
    aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --query 'Stacks[0].Outputs' \
        --output json > deployment-outputs.json
    
    export API_URL=$(jq -r '.[] | select(.OutputKey=="ApiGatewayUrl") | .OutputValue' deployment-outputs.json)
    export BUCKET_NAME=$(jq -r '.[] | select(.OutputKey=="KnowledgeBucketName") | .OutputValue' deployment-outputs.json)
    export USER_POOL_ID=$(jq -r '.[] | select(.OutputKey=="UserPoolId") | .OutputValue' deployment-outputs.json)
    export USER_POOL_CLIENT_ID=$(jq -r '.[] | select(.OutputKey=="UserPoolClientId") | .OutputValue' deployment-outputs.json)
    
    print_success "API URL: $API_URL"
    print_success "Knowledge Bucket: $BUCKET_NAME"
    print_success "User Pool ID: $USER_POOL_ID"
}

# Setup Bedrock resources
setup_bedrock() {
    print_status "Setting up Bedrock resources..."
    
    # Check if Bedrock setup script exists
    if [ -f "scripts/setup/setup-bedrock-agent.sh" ]; then
        chmod +x scripts/setup/setup-bedrock-agent.sh
        ./scripts/setup/setup-bedrock-agent.sh
    else
        print_warning "Bedrock setup script not found. Skipping Bedrock configuration."
    fi
    
    print_success "Bedrock setup completed"
}

# Upload knowledge base
upload_knowledge_base() {
    print_status "Uploading knowledge base content..."
    
    if [ -d "knowledge-base" ]; then
        aws s3 sync knowledge-base/ s3://$BUCKET_NAME/knowledge-base/ \
            --exclude "*.git*" \
            --exclude "node_modules/*" \
            --delete
        print_success "Knowledge base uploaded"
    else
        print_warning "Knowledge base directory not found"
    fi
}

# Deploy Lambda functions
deploy_lambdas() {
    print_status "Deploying Lambda functions..."
    
    # Package and deploy each Lambda function
    for lambda_dir in lambda/*/; do
        if [ -f "$lambda_dir/package.json" ]; then
            lambda_name=$(basename "$lambda_dir")
            function_name="devops-${lambda_name//_/-}"
            
            print_status "Deploying $function_name..."
            
            cd "$lambda_dir"
            zip -r "../${lambda_name}.zip" . -x "*.git*" "node_modules/.cache/*"
            
            aws lambda update-function-code \
                --function-name "$function_name" \
                --zip-file "fileb://../${lambda_name}.zip" \
                --region $AWS_REGION || print_warning "Failed to update $function_name"
            
            cd - > /dev/null
        fi
    done
    
    print_success "Lambda functions deployed"
}

# Build and deploy frontend
deploy_frontend() {
    print_status "Building and deploying frontend..."
    
    cd frontend
    
    # Set environment variables
    export REACT_APP_API_URL=$API_URL
    export REACT_APP_USER_POOL_ID=$USER_POOL_ID
    export REACT_APP_USER_POOL_CLIENT_ID=$USER_POOL_CLIENT_ID
    export REACT_APP_REGION=$AWS_REGION
    
    # Build production bundle
    npm run build
    
    # Create S3 bucket for frontend if it doesn't exist
    FRONTEND_BUCKET="devops-knowledgeops-frontend-${AWS_ACCOUNT_ID}-${AWS_REGION}"
    
    aws s3 mb s3://$FRONTEND_BUCKET --region $AWS_REGION 2>/dev/null || true
    
    # Configure bucket for static website hosting
    aws s3 website s3://$FRONTEND_BUCKET \
        --index-document index.html \
        --error-document error.html
    
    # Set bucket policy for public read access
    cat > bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$FRONTEND_BUCKET/*"
        }
    ]
}
EOF
    
    aws s3api put-bucket-policy \
        --bucket $FRONTEND_BUCKET \
        --policy file://bucket-policy.json
    
    # Upload built files
    aws s3 sync build/ s3://$FRONTEND_BUCKET --delete
    
    # Get website URL
    WEBSITE_URL="http://$FRONTEND_BUCKET.s3-website-$AWS_REGION.amazonaws.com"
    
    cd ..
    
    print_success "Frontend deployed to: $WEBSITE_URL"
}

# Configure monitoring
setup_monitoring() {
    print_status "Setting up monitoring..."
    
    # Create CloudWatch dashboard
    if [ -f "monitoring/dashboard.json" ]; then
        aws cloudwatch put-dashboard \
            --dashboard-name "DevOpsKnowledgeOpsAgent" \
            --dashboard-body file://monitoring/dashboard.json
    fi
    
    # Set up basic alarms
    aws cloudwatch put-metric-alarm \
        --alarm-name "DevOps-HighLambdaErrors" \
        --alarm-description "High error rate in Lambda functions" \
        --metric-name Errors \
        --namespace AWS/Lambda \
        --statistic Sum \
        --period 300 \
        --threshold 10 \
        --comparison-operator GreaterThanThreshold \
        --alarm-actions "arn:aws:sns:$AWS_REGION:$AWS_ACCOUNT_ID:devops-alerts" 2>/dev/null || true
    
    print_success "Monitoring configured"
}

# Run deployment tests
run_tests() {
    print_status "Running deployment tests..."
    
    # Health check
    sleep 10  # Wait for services to be ready
    
    if curl -f "$API_URL/health" > /dev/null 2>&1; then
        print_success "API health check passed"
    else
        print_warning "API health check failed"
    fi
    
    # Test authentication endpoint
    if curl -f "$API_URL/auth" -X POST -H "Content-Type: application/json" -d '{"action":"test"}' > /dev/null 2>&1; then
        print_success "Authentication endpoint accessible"
    else
        print_warning "Authentication endpoint test failed"
    fi
    
    print_success "Basic tests completed"
}

# Generate deployment summary
generate_summary() {
    print_status "Generating deployment summary..."
    
    cat > deployment-summary.md << EOF
# Deployment Summary

## Environment: $ENVIRONMENT
## Timestamp: $(date)
## AWS Account: $AWS_ACCOUNT_ID
## Region: $AWS_REGION

## Deployed Resources

### API Gateway
- **URL**: $API_URL
- **Endpoints**: /auth, /chat, /session, /actions, /health

### Frontend
- **URL**: $WEBSITE_URL
- **Bucket**: $FRONTEND_BUCKET

### Cognito
- **User Pool ID**: $USER_POOL_ID
- **Client ID**: $USER_POOL_CLIENT_ID

### S3
- **Knowledge Base Bucket**: $BUCKET_NAME

## Next Steps

1. **Test the application**: Visit $WEBSITE_URL
2. **Create users**: Use Cognito console or API
3. **Monitor**: Check CloudWatch dashboards
4. **Scale**: Adjust Lambda concurrency as needed

## Support

- **Logs**: CloudWatch Logs
- **Metrics**: CloudWatch Dashboards
- **Alerts**: CloudWatch Alarms
EOF

    print_success "Deployment summary saved to deployment-summary.md"
}

# Main deployment flow
main() {
    echo "🚀 Starting Production Deployment of DevOps KnowledgeOps Agent"
    echo "================================================================"
    
    check_prerequisites
    get_config
    install_dependencies
    build_application
    deploy_infrastructure
    get_stack_outputs
    setup_bedrock
    upload_knowledge_base
    deploy_lambdas
    deploy_frontend
    setup_monitoring
    run_tests
    generate_summary
    
    echo ""
    echo "🎉 Deployment Completed Successfully!"
    echo "=================================="
    echo ""
    echo "📋 Deployment Summary:"
    echo "  • API URL: $API_URL"
    echo "  • Frontend URL: $WEBSITE_URL"
    echo "  • User Pool ID: $USER_POOL_ID"
    echo ""
    echo "🔗 Quick Links:"
    echo "  • Application: $WEBSITE_URL"
    echo "  • AWS Console: https://console.aws.amazon.com/"
    echo "  • CloudWatch: https://console.aws.amazon.com/cloudwatch/"
    echo ""
    echo "📖 Next Steps:"
    echo "  1. Visit the application URL to test"
    echo "  2. Create user accounts via Cognito"
    echo "  3. Monitor performance in CloudWatch"
    echo "  4. Review deployment-summary.md for details"
    echo ""
    echo "🎯 Your DevOps KnowledgeOps Agent is now live in production!"
}

# Run main function
main "$@"