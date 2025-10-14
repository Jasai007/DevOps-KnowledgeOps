#!/bin/bash

# Rollback Script for DevOps KnowledgeOps Agent
# This script handles rollback scenarios for production deployments

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

# Functions
print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --lambda-only     Rollback only Lambda functions"
    echo "  --frontend-only   Rollback only frontend"
    echo "  --full           Full rollback (infrastructure + application)"
    echo "  --to-version     Rollback to specific version"
    echo "  --dry-run        Show what would be rolled back without executing"
    echo "  --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --lambda-only                    # Rollback Lambda functions only"
    echo "  $0 --frontend-only                  # Rollback frontend only"
    echo "  $0 --full                          # Full rollback"
    echo "  $0 --to-version v1.2.3             # Rollback to specific version"
    echo "  $0 --dry-run --full                # Dry run of full rollback"
}

# Parse command line arguments
parse_args() {
    ROLLBACK_TYPE=""
    TARGET_VERSION=""
    DRY_RUN=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --lambda-only)
                ROLLBACK_TYPE="lambda"
                shift
                ;;
            --frontend-only)
                ROLLBACK_TYPE="frontend"
                shift
                ;;
            --full)
                ROLLBACK_TYPE="full"
                shift
                ;;
            --to-version)
                TARGET_VERSION="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    if [ -z "$ROLLBACK_TYPE" ]; then
        print_error "Rollback type must be specified"
        show_usage
        exit 1
    fi
}

# Get current deployment info
get_current_info() {
    print_status "Getting current deployment information..."
    
    export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    export AWS_REGION=$REGION
    
    # Get stack outputs
    if aws cloudformation describe-stacks --stack-name $STACK_NAME &> /dev/null; then
        aws cloudformation describe-stacks \
            --stack-name $STACK_NAME \
            --query 'Stacks[0].Outputs' \
            --output json > current-outputs.json
        
        export API_URL=$(jq -r '.[] | select(.OutputKey=="ApiGatewayUrl") | .OutputValue' current-outputs.json)
        export BUCKET_NAME=$(jq -r '.[] | select(.OutputKey=="KnowledgeBucketName") | .OutputValue' current-outputs.json)
        export FRONTEND_BUCKET="devops-knowledgeops-frontend-${AWS_ACCOUNT_ID}-${AWS_REGION}"
        
        print_success "Current deployment found"
        print_status "API URL: $API_URL"
        print_status "Knowledge Bucket: $BUCKET_NAME"
    else
        print_error "Stack $STACK_NAME not found"
        exit 1
    fi
}

# List available versions
list_versions() {
    print_status "Available versions for rollback:"
    
    # List Lambda function versions
    echo ""
    echo "Lambda Function Versions:"
    for func in devops-chat-processor devops-session-handler devops-actions-handler; do
        if aws lambda get-function --function-name $func &> /dev/null; then
            versions=$(aws lambda list-versions-by-function --function-name $func --query 'Versions[?Version!=`$LATEST`].Version' --output text)
            echo "  $func: $versions"
        fi
    done
    
    # List S3 versions for frontend
    echo ""
    echo "Frontend Versions (S3 object versions):"
    if aws s3api head-bucket --bucket $FRONTEND_BUCKET &> /dev/null; then
        aws s3api list-object-versions --bucket $FRONTEND_BUCKET --prefix "index.html" --query 'Versions[0:5].[VersionId,LastModified]' --output table
    fi
    
    # List CloudFormation stack events
    echo ""
    echo "Recent Stack Updates:"
    aws cloudformation describe-stack-events --stack-name $STACK_NAME --query 'StackEvents[0:5].[Timestamp,LogicalResourceId,ResourceStatus]' --output table
}

# Rollback Lambda functions
rollback_lambdas() {
    print_status "Rolling back Lambda functions..."
    
    local functions=("devops-chat-processor" "devops-session-handler" "devops-actions-handler")
    
    for func in "${functions[@]}"; do
        if aws lambda get-function --function-name $func &> /dev/null; then
            print_status "Rolling back $func..."
            
            if [ -n "$TARGET_VERSION" ]; then
                # Rollback to specific version
                if [ "$DRY_RUN" = true ]; then
                    print_status "[DRY RUN] Would rollback $func to version $TARGET_VERSION"
                else
                    aws lambda update-function-code \
                        --function-name $func \
                        --s3-bucket "lambda-deployments-$AWS_ACCOUNT_ID" \
                        --s3-key "$func/$TARGET_VERSION.zip" || print_warning "Failed to rollback $func"
                fi
            else
                # Rollback to previous version
                local versions=$(aws lambda list-versions-by-function --function-name $func --query 'Versions[?Version!=`$LATEST`].Version' --output text)
                local prev_version=$(echo $versions | awk '{print $(NF-1)}')  # Second to last version
                
                if [ -n "$prev_version" ]; then
                    if [ "$DRY_RUN" = true ]; then
                        print_status "[DRY RUN] Would rollback $func to version $prev_version"
                    else
                        aws lambda update-alias \
                            --function-name $func \
                            --name LIVE \
                            --function-version $prev_version || print_warning "Failed to rollback $func"
                    fi
                else
                    print_warning "No previous version found for $func"
                fi
            fi
        else
            print_warning "Function $func not found"
        fi
    done
    
    print_success "Lambda rollback completed"
}

# Rollback frontend
rollback_frontend() {
    print_status "Rolling back frontend..."
    
    if aws s3api head-bucket --bucket $FRONTEND_BUCKET &> /dev/null; then
        if [ -n "$TARGET_VERSION" ]; then
            # Rollback to specific version
            if [ "$DRY_RUN" = true ]; then
                print_status "[DRY RUN] Would rollback frontend to version $TARGET_VERSION"
            else
                # Download and deploy specific version
                aws s3 sync s3://frontend-versions-$AWS_ACCOUNT_ID/$TARGET_VERSION/ s3://$FRONTEND_BUCKET/ --delete
            fi
        else
            # Rollback to previous version (restore from backup)
            local backup_bucket="devops-knowledgeops-frontend-backup-${AWS_ACCOUNT_ID}"
            
            if aws s3api head-bucket --bucket $backup_bucket &> /dev/null; then
                if [ "$DRY_RUN" = true ]; then
                    print_status "[DRY RUN] Would restore frontend from backup bucket"
                else
                    aws s3 sync s3://$backup_bucket/ s3://$FRONTEND_BUCKET/ --delete
                fi
            else
                print_warning "No backup bucket found for frontend rollback"
            fi
        fi
    else
        print_error "Frontend bucket $FRONTEND_BUCKET not found"
    fi
    
    print_success "Frontend rollback completed"
}

# Rollback infrastructure
rollback_infrastructure() {
    print_status "Rolling back infrastructure..."
    
    if [ "$DRY_RUN" = true ]; then
        print_status "[DRY RUN] Would rollback CloudFormation stack"
        aws cloudformation describe-stack-events --stack-name $STACK_NAME --query 'StackEvents[0:10].[Timestamp,LogicalResourceId,ResourceStatus,ResourceStatusReason]' --output table
    else
        # Get previous stack template
        local change_sets=$(aws cloudformation list-change-sets --stack-name $STACK_NAME --query 'Summaries[0].ChangeSetId' --output text)
        
        if [ "$change_sets" != "None" ] && [ -n "$change_sets" ]; then
            print_warning "Rolling back infrastructure changes..."
            
            # This is a simplified rollback - in production, you'd want more sophisticated change set management
            print_warning "Manual intervention required for infrastructure rollback"
            print_status "Consider using: aws cloudformation cancel-update-stack --stack-name $STACK_NAME"
        else
            print_warning "No change sets found for rollback"
        fi
    fi
}

# Create backup before rollback
create_backup() {
    print_status "Creating backup before rollback..."
    
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_prefix="rollback-backup-$timestamp"
    
    # Backup current Lambda functions
    for func in devops-chat-processor devops-session-handler devops-actions-handler; do
        if aws lambda get-function --function-name $func &> /dev/null; then
            if [ "$DRY_RUN" = false ]; then
                aws lambda get-function --function-name $func --query 'Code.Location' --output text | xargs wget -O "${func}-${timestamp}.zip"
                print_status "Backed up $func to ${func}-${timestamp}.zip"
            fi
        fi
    done
    
    # Backup current frontend
    if aws s3api head-bucket --bucket $FRONTEND_BUCKET &> /dev/null; then
        local backup_bucket="devops-knowledgeops-frontend-backup-${AWS_ACCOUNT_ID}"
        
        if [ "$DRY_RUN" = false ]; then
            aws s3 mb s3://$backup_bucket 2>/dev/null || true
            aws s3 sync s3://$FRONTEND_BUCKET/ s3://$backup_bucket/$backup_prefix/
            print_status "Backed up frontend to s3://$backup_bucket/$backup_prefix/"
        fi
    fi
    
    print_success "Backup completed"
}

# Verify rollback
verify_rollback() {
    print_status "Verifying rollback..."
    
    if [ "$DRY_RUN" = true ]; then
        print_status "[DRY RUN] Would verify rollback success"
        return
    fi
    
    # Wait for services to stabilize
    sleep 30
    
    # Health check
    if curl -f "$API_URL/health" > /dev/null 2>&1; then
        print_success "API health check passed"
    else
        print_error "API health check failed after rollback"
    fi
    
    # Check Lambda function status
    for func in devops-chat-processor devops-session-handler devops-actions-handler; do
        local state=$(aws lambda get-function --function-name $func --query 'Configuration.State' --output text 2>/dev/null || echo "NotFound")
        if [ "$state" = "Active" ]; then
            print_success "$func is active"
        else
            print_warning "$func state: $state"
        fi
    done
    
    # Check frontend accessibility
    local website_url="http://$FRONTEND_BUCKET.s3-website-$AWS_REGION.amazonaws.com"
    if curl -f "$website_url" > /dev/null 2>&1; then
        print_success "Frontend is accessible"
    else
        print_warning "Frontend accessibility check failed"
    fi
    
    print_success "Rollback verification completed"
}

# Generate rollback report
generate_report() {
    print_status "Generating rollback report..."
    
    local timestamp=$(date)
    
    cat > rollback-report.md << EOF
# Rollback Report

## Rollback Details
- **Type**: $ROLLBACK_TYPE
- **Target Version**: ${TARGET_VERSION:-"Previous version"}
- **Timestamp**: $timestamp
- **Dry Run**: $DRY_RUN
- **AWS Account**: $AWS_ACCOUNT_ID
- **Region**: $AWS_REGION

## Actions Taken

### Lambda Functions
$(if [ "$ROLLBACK_TYPE" = "lambda" ] || [ "$ROLLBACK_TYPE" = "full" ]; then
    echo "- Rolled back Lambda functions to previous versions"
    echo "- Functions affected: devops-chat-processor, devops-session-handler, devops-actions-handler"
else
    echo "- No Lambda rollback performed"
fi)

### Frontend
$(if [ "$ROLLBACK_TYPE" = "frontend" ] || [ "$ROLLBACK_TYPE" = "full" ]; then
    echo "- Rolled back frontend deployment"
    echo "- Bucket: $FRONTEND_BUCKET"
else
    echo "- No frontend rollback performed"
fi)

### Infrastructure
$(if [ "$ROLLBACK_TYPE" = "full" ]; then
    echo "- Infrastructure rollback initiated"
    echo "- Manual verification may be required"
else
    echo "- No infrastructure rollback performed"
fi)

## Verification Results
- API Health Check: $(curl -f "$API_URL/health" > /dev/null 2>&1 && echo "✅ Passed" || echo "❌ Failed")
- Frontend Access: $(curl -f "http://$FRONTEND_BUCKET.s3-website-$AWS_REGION.amazonaws.com" > /dev/null 2>&1 && echo "✅ Accessible" || echo "❌ Not accessible")

## Next Steps
1. Monitor application performance
2. Verify user functionality
3. Check CloudWatch logs for errors
4. Consider root cause analysis for the issue that required rollback

## Support
- CloudWatch Logs: https://console.aws.amazon.com/cloudwatch/
- Lambda Console: https://console.aws.amazon.com/lambda/
- S3 Console: https://console.aws.amazon.com/s3/
EOF

    print_success "Rollback report saved to rollback-report.md"
}

# Main rollback flow
main() {
    echo "🔄 DevOps KnowledgeOps Agent Rollback"
    echo "===================================="
    
    parse_args "$@"
    get_current_info
    
    if [ "$DRY_RUN" = true ]; then
        print_warning "DRY RUN MODE - No actual changes will be made"
    fi
    
    print_status "Rollback type: $ROLLBACK_TYPE"
    print_status "Target version: ${TARGET_VERSION:-"Previous version"}"
    
    # Show available versions
    list_versions
    
    # Confirm rollback
    if [ "$DRY_RUN" = false ]; then
        echo ""
        read -p "Are you sure you want to proceed with the rollback? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Rollback cancelled"
            exit 0
        fi
    fi
    
    # Create backup
    create_backup
    
    # Perform rollback based on type
    case $ROLLBACK_TYPE in
        lambda)
            rollback_lambdas
            ;;
        frontend)
            rollback_frontend
            ;;
        full)
            rollback_lambdas
            rollback_frontend
            rollback_infrastructure
            ;;
    esac
    
    # Verify rollback
    verify_rollback
    
    # Generate report
    generate_report
    
    echo ""
    if [ "$DRY_RUN" = true ]; then
        print_success "Dry run completed - no changes were made"
    else
        print_success "Rollback completed successfully!"
    fi
    echo ""
    print_status "Check rollback-report.md for detailed information"
}

# Run main function
main "$@"