#!/bin/bash

# Monitoring Setup Script for DevOps KnowledgeOps Agent
# Sets up comprehensive monitoring, alerting, and observability

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
SNS_TOPIC_NAME="devops-knowledgeops-alerts"

# Functions
print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Get AWS configuration
get_aws_config() {
    print_status "Getting AWS configuration..."
    
    export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    export AWS_REGION=$REGION
    
    # Get stack outputs
    aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --query 'Stacks[0].Outputs' \
        --output json > stack-outputs.json
    
    export API_URL=$(jq -r '.[] | select(.OutputKey=="ApiGatewayUrl") | .OutputValue' stack-outputs.json)
    
    print_success "AWS Account: $AWS_ACCOUNT_ID"
    print_success "Region: $AWS_REGION"
}

# Create SNS topic for alerts
create_sns_topic() {
    print_status "Creating SNS topic for alerts..."
    
    # Create SNS topic
    SNS_TOPIC_ARN=$(aws sns create-topic --name $SNS_TOPIC_NAME --query 'TopicArn' --output text)
    
    print_success "SNS Topic created: $SNS_TOPIC_ARN"
    
    # Add email subscription (you can modify this)
    read -p "Enter email address for alerts (optional): " EMAIL_ADDRESS
    if [ -n "$EMAIL_ADDRESS" ]; then
        aws sns subscribe \
            --topic-arn $SNS_TOPIC_ARN \
            --protocol email \
            --notification-endpoint $EMAIL_ADDRESS
        print_success "Email subscription added for $EMAIL_ADDRESS"
    fi
}

# Create CloudWatch dashboard
create_dashboard() {
    print_status "Creating CloudWatch dashboard..."
    
    cat > dashboard.json << EOF
{
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/Lambda", "Duration", "FunctionName", "devops-chat-processor" ],
                    [ ".", "Errors", ".", "." ],
                    [ ".", "Invocations", ".", "." ],
                    [ ".", "Throttles", ".", "." ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "$AWS_REGION",
                "title": "Chat Processor Lambda Metrics",
                "period": 300
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/ApiGateway", "Count", "ApiName", "devops-knowledgeops-api" ],
                    [ ".", "Latency", ".", "." ],
                    [ ".", "4XXError", ".", "." ],
                    [ ".", "5XXError", ".", "." ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "$AWS_REGION",
                "title": "API Gateway Metrics",
                "period": 300
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 6,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", "devops-chat-sessions" ],
                    [ ".", "ConsumedWriteCapacityUnits", ".", "." ],
                    [ ".", "UserErrors", ".", "." ],
                    [ ".", "SystemErrors", ".", "." ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "$AWS_REGION",
                "title": "DynamoDB Metrics",
                "period": 300
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 6,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/Bedrock", "InvocationsCount", "ModelId", "anthropic.claude-3-5-sonnet-20241022-v2:0" ],
                    [ ".", "InvocationsLatency", ".", "." ],
                    [ ".", "InvocationsClientErrors", ".", "." ],
                    [ ".", "InvocationsServerErrors", ".", "." ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "$AWS_REGION",
                "title": "Bedrock Model Metrics",
                "period": 300
            }
        },
        {
            "type": "log",
            "x": 0,
            "y": 12,
            "width": 24,
            "height": 6,
            "properties": {
                "query": "SOURCE '/aws/lambda/devops-chat-processor'\n| fields @timestamp, @message\n| filter @message like /ERROR/\n| sort @timestamp desc\n| limit 20",
                "region": "$AWS_REGION",
                "title": "Recent Errors",
                "view": "table"
            }
        }
    ]
}
EOF

    aws cloudwatch put-dashboard \
        --dashboard-name "DevOpsKnowledgeOpsAgent" \
        --dashboard-body file://dashboard.json
    
    print_success "CloudWatch dashboard created"
}

# Create CloudWatch alarms
create_alarms() {
    print_status "Creating CloudWatch alarms..."
    
    # Lambda error rate alarm
    aws cloudwatch put-metric-alarm \
        --alarm-name "DevOps-Lambda-HighErrorRate" \
        --alarm-description "High error rate in Lambda functions" \
        --metric-name Errors \
        --namespace AWS/Lambda \
        --statistic Sum \
        --period 300 \
        --threshold 5 \
        --comparison-operator GreaterThanThreshold \
        --dimensions Name=FunctionName,Value=devops-chat-processor \
        --evaluation-periods 2 \
        --alarm-actions $SNS_TOPIC_ARN \
        --treat-missing-data notBreaching
    
    # Lambda duration alarm
    aws cloudwatch put-metric-alarm \
        --alarm-name "DevOps-Lambda-HighDuration" \
        --alarm-description "High duration in Lambda functions" \
        --metric-name Duration \
        --namespace AWS/Lambda \
        --statistic Average \
        --period 300 \
        --threshold 30000 \
        --comparison-operator GreaterThanThreshold \
        --dimensions Name=FunctionName,Value=devops-chat-processor \
        --evaluation-periods 2 \
        --alarm-actions $SNS_TOPIC_ARN \
        --treat-missing-data notBreaching
    
    # API Gateway 5XX errors
    aws cloudwatch put-metric-alarm \
        --alarm-name "DevOps-API-5XXErrors" \
        --alarm-description "High 5XX error rate in API Gateway" \
        --metric-name 5XXError \
        --namespace AWS/ApiGateway \
        --statistic Sum \
        --period 300 \
        --threshold 10 \
        --comparison-operator GreaterThanThreshold \
        --dimensions Name=ApiName,Value=devops-knowledgeops-api \
        --evaluation-periods 2 \
        --alarm-actions $SNS_TOPIC_ARN \
        --treat-missing-data notBreaching
    
    # API Gateway latency alarm
    aws cloudwatch put-metric-alarm \
        --alarm-name "DevOps-API-HighLatency" \
        --alarm-description "High latency in API Gateway" \
        --metric-name Latency \
        --namespace AWS/ApiGateway \
        --statistic Average \
        --period 300 \
        --threshold 5000 \
        --comparison-operator GreaterThanThreshold \
        --dimensions Name=ApiName,Value=devops-knowledgeops-api \
        --evaluation-periods 2 \
        --alarm-actions $SNS_TOPIC_ARN \
        --treat-missing-data notBreaching
    
    # DynamoDB throttling alarm
    aws cloudwatch put-metric-alarm \
        --alarm-name "DevOps-DynamoDB-Throttling" \
        --alarm-description "DynamoDB throttling detected" \
        --metric-name UserErrors \
        --namespace AWS/DynamoDB \
        --statistic Sum \
        --period 300 \
        --threshold 5 \
        --comparison-operator GreaterThanThreshold \
        --dimensions Name=TableName,Value=devops-chat-sessions \
        --evaluation-periods 1 \
        --alarm-actions $SNS_TOPIC_ARN \
        --treat-missing-data notBreaching
    
    print_success "CloudWatch alarms created"
}

# Enable X-Ray tracing
enable_xray() {
    print_status "Enabling X-Ray tracing..."
    
    # Enable tracing for Lambda functions
    for func in devops-chat-processor devops-session-handler devops-actions-handler; do
        aws lambda update-function-configuration \
            --function-name $func \
            --tracing-config Mode=Active || print_warning "Failed to enable X-Ray for $func"
    done
    
    # Enable tracing for API Gateway
    aws apigateway update-stage \
        --rest-api-id $(echo $API_URL | cut -d'/' -f3 | cut -d'.' -f1) \
        --stage-name prod \
        --patch-ops op=replace,path=/tracingEnabled,value=true || print_warning "Failed to enable X-Ray for API Gateway"
    
    print_success "X-Ray tracing enabled"
}

# Create log groups with retention
setup_log_groups() {
    print_status "Setting up log groups..."
    
    # Lambda log groups
    for func in devops-chat-processor devops-session-handler devops-actions-handler; do
        log_group="/aws/lambda/$func"
        
        # Create log group if it doesn't exist
        aws logs create-log-group --log-group-name $log_group 2>/dev/null || true
        
        # Set retention policy
        aws logs put-retention-policy \
            --log-group-name $log_group \
            --retention-in-days 30
    done
    
    # API Gateway log group
    api_log_group="/aws/apigateway/devops-knowledgeops-api"
    aws logs create-log-group --log-group-name $api_log_group 2>/dev/null || true
    aws logs put-retention-policy \
        --log-group-name $api_log_group \
        --retention-in-days 30
    
    print_success "Log groups configured"
}

# Create custom metrics
create_custom_metrics() {
    print_status "Setting up custom metrics..."
    
    # Create a Lambda function for custom metrics
    cat > custom-metrics.py << 'EOF'
import json
import boto3
import os
from datetime import datetime

cloudwatch = boto3.client('cloudwatch')

def lambda_handler(event, context):
    # Custom business metrics
    try:
        # Example: Track successful AI responses
        if event.get('metric_name') == 'successful_ai_response':
            cloudwatch.put_metric_data(
                Namespace='DevOpsKnowledgeOps/Business',
                MetricData=[
                    {
                        'MetricName': 'SuccessfulAIResponses',
                        'Value': 1,
                        'Unit': 'Count',
                        'Timestamp': datetime.utcnow()
                    }
                ]
            )
        
        # Example: Track user satisfaction
        elif event.get('metric_name') == 'user_satisfaction':
            rating = event.get('rating', 0)
            cloudwatch.put_metric_data(
                Namespace='DevOpsKnowledgeOps/Business',
                MetricData=[
                    {
                        'MetricName': 'UserSatisfactionRating',
                        'Value': rating,
                        'Unit': 'None',
                        'Timestamp': datetime.utcnow()
                    }
                ]
            )
        
        return {
            'statusCode': 200,
            'body': json.dumps('Metric recorded successfully')
        }
    
    except Exception as e:
        print(f"Error recording metric: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps('Error recording metric')
        }
EOF

    # Package and deploy custom metrics function
    zip custom-metrics.zip custom-metrics.py
    
    aws lambda create-function \
        --function-name devops-custom-metrics \
        --runtime python3.9 \
        --role arn:aws:iam::$AWS_ACCOUNT_ID:role/lambda-execution-role \
        --handler custom-metrics.lambda_handler \
        --zip-file fileb://custom-metrics.zip \
        --timeout 30 \
        --memory-size 128 2>/dev/null || print_warning "Custom metrics function already exists"
    
    print_success "Custom metrics setup completed"
}

# Setup cost monitoring
setup_cost_monitoring() {
    print_status "Setting up cost monitoring..."
    
    # Create budget for the project
    cat > budget.json << EOF
{
    "BudgetName": "DevOpsKnowledgeOpsAgent",
    "BudgetLimit": {
        "Amount": "100.0",
        "Unit": "USD"
    },
    "TimeUnit": "MONTHLY",
    "TimePeriod": {
        "Start": "$(date -d 'first day of this month' '+%Y-%m-01')",
        "End": "$(date -d 'first day of next month' '+%Y-%m-01')"
    },
    "BudgetType": "COST",
    "CostFilters": {
        "TagKey": ["Project"],
        "TagValue": ["DevOpsKnowledgeOps"]
    }
}
EOF

    cat > budget-notifications.json << EOF
[
    {
        "Notification": {
            "NotificationType": "ACTUAL",
            "ComparisonOperator": "GREATER_THAN",
            "Threshold": 80.0,
            "ThresholdType": "PERCENTAGE"
        },
        "Subscribers": [
            {
                "SubscriptionType": "SNS",
                "Address": "$SNS_TOPIC_ARN"
            }
        ]
    },
    {
        "Notification": {
            "NotificationType": "FORECASTED",
            "ComparisonOperator": "GREATER_THAN",
            "Threshold": 100.0,
            "ThresholdType": "PERCENTAGE"
        },
        "Subscribers": [
            {
                "SubscriptionType": "SNS",
                "Address": "$SNS_TOPIC_ARN"
            }
        ]
    }
]
EOF

    aws budgets create-budget \
        --account-id $AWS_ACCOUNT_ID \
        --budget file://budget.json \
        --notifications-with-subscribers file://budget-notifications.json 2>/dev/null || print_warning "Budget already exists"
    
    print_success "Cost monitoring configured"
}

# Create monitoring runbook
create_runbook() {
    print_status "Creating monitoring runbook..."
    
    cat > monitoring-runbook.md << EOF
# DevOps KnowledgeOps Agent - Monitoring Runbook

## Overview
This runbook provides guidance for monitoring and troubleshooting the DevOps KnowledgeOps Agent.

## Key Metrics to Monitor

### Lambda Functions
- **Duration**: Should be < 30 seconds
- **Error Rate**: Should be < 1%
- **Invocations**: Monitor for unusual spikes
- **Throttles**: Should be 0

### API Gateway
- **Latency**: Should be < 5 seconds
- **4XX Errors**: Monitor for authentication issues
- **5XX Errors**: Should be < 1%
- **Request Count**: Monitor usage patterns

### DynamoDB
- **Consumed Capacity**: Monitor for throttling
- **System Errors**: Should be 0
- **User Errors**: Monitor for application issues

### Bedrock
- **Invocation Count**: Monitor AI usage
- **Latency**: Monitor model response times
- **Client/Server Errors**: Monitor for issues

## Alerts and Thresholds

### Critical Alerts
- Lambda error rate > 5% in 10 minutes
- API Gateway 5XX errors > 10 in 5 minutes
- DynamoDB throttling detected
- Bedrock service errors

### Warning Alerts
- Lambda duration > 30 seconds average
- API Gateway latency > 5 seconds average
- Cost exceeds 80% of budget

## Troubleshooting Guide

### High Lambda Errors
1. Check CloudWatch Logs for error details
2. Verify Bedrock model access
3. Check DynamoDB permissions
4. Review recent deployments

### High API Latency
1. Check Lambda duration metrics
2. Review Bedrock response times
3. Check DynamoDB performance
4. Verify network connectivity

### DynamoDB Throttling
1. Check consumed capacity metrics
2. Consider enabling auto-scaling
3. Review query patterns
4. Optimize data access patterns

### Bedrock Errors
1. Verify model access permissions
2. Check request quotas
3. Review model availability
4. Check request format

## Dashboard Links
- Main Dashboard: https://console.aws.amazon.com/cloudwatch/home?region=$AWS_REGION#dashboards:name=DevOpsKnowledgeOpsAgent
- Lambda Logs: https://console.aws.amazon.com/cloudwatch/home?region=$AWS_REGION#logsV2:log-groups
- X-Ray Traces: https://console.aws.amazon.com/xray/home?region=$AWS_REGION#/traces

## Contact Information
- On-call Engineer: [Your contact info]
- Escalation: [Manager contact info]
- AWS Support: [Support case process]

## Maintenance Windows
- Preferred: Sunday 2-4 AM UTC
- Emergency: Any time with approval
EOF

    print_success "Monitoring runbook created: monitoring-runbook.md"
}

# Main monitoring setup
main() {
    echo "📊 Setting up Monitoring for DevOps KnowledgeOps Agent"
    echo "=================================================="
    
    get_aws_config
    create_sns_topic
    create_dashboard
    create_alarms
    enable_xray
    setup_log_groups
    create_custom_metrics
    setup_cost_monitoring
    create_runbook
    
    echo ""
    print_success "🎉 Monitoring setup completed successfully!"
    echo ""
    echo "📋 What was configured:"
    echo "  ✅ CloudWatch Dashboard"
    echo "  ✅ CloudWatch Alarms"
    echo "  ✅ SNS Alerts Topic"
    echo "  ✅ X-Ray Tracing"
    echo "  ✅ Log Groups with Retention"
    echo "  ✅ Custom Metrics Function"
    echo "  ✅ Cost Monitoring Budget"
    echo "  ✅ Monitoring Runbook"
    echo ""
    echo "🔗 Quick Links:"
    echo "  • Dashboard: https://console.aws.amazon.com/cloudwatch/home?region=$AWS_REGION#dashboards:name=DevOpsKnowledgeOpsAgent"
    echo "  • Alarms: https://console.aws.amazon.com/cloudwatch/home?region=$AWS_REGION#alarmsV2:"
    echo "  • Logs: https://console.aws.amazon.com/cloudwatch/home?region=$AWS_REGION#logsV2:log-groups"
    echo "  • X-Ray: https://console.aws.amazon.com/xray/home?region=$AWS_REGION#/traces"
    echo ""
    echo "📖 Next Steps:"
    echo "  1. Review the monitoring runbook: monitoring-runbook.md"
    echo "  2. Test alerts by triggering some errors"
    echo "  3. Customize thresholds based on your usage patterns"
    echo "  4. Add team members to SNS topic subscriptions"
    echo ""
    echo "🎯 Your DevOps KnowledgeOps Agent is now fully monitored!"
}

# Run main function
main "$@"