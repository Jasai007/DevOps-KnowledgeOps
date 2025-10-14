# AWS Deployment Plan - DevOps KnowledgeOps Agent

## 🎯 Deployment Overview

This plan outlines the complete AWS deployment strategy for the DevOps KnowledgeOps Agent, including infrastructure, CI/CD, monitoring, and production considerations.

## 🏗️ Architecture Components

### Core Infrastructure
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   CloudFront    │────│   S3 (Frontend)  │    │  API Gateway    │
│   (CDN)         │    │   Static Hosting │    │   (REST API)    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                         │
                       ┌─────────────────────────────────┼─────────────────┐
                       │                                 │                 │
                ┌──────▼──────┐    ┌──────────────┐    ┌▼─────────────┐   │
                │   Lambda    │    │   Cognito    │    │   Lambda     │   │
                │ Auth Handler│    │ User Pool    │    │Chat Processor│   │
                └─────────────┘    └──────────────┘    └──────────────┘   │
                                                                          │
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐      │
│   DynamoDB      │    │      S3          │    │   Bedrock       │      │
│ Chat Sessions   │    │ Knowledge Base   │    │ Agent & Models  │      │
└─────────────────┘    └──────────────────┘    └─────────────────┘      │
                                                         │                │
                       ┌─────────────────────────────────┼────────────────┘
                       │                                 │
                ┌──────▼──────┐    ┌──────────────┐    ┌▼─────────────┐
                │ OpenSearch  │    │   Lambda     │    │   Lambda     │
                │ Serverless  │    │Session Mgmt  │    │   Actions    │
                └─────────────┘    └──────────────┘    └──────────────┘
```

## 📋 Deployment Phases

### Phase 1: Pre-Deployment Setup (15 minutes)

#### 1.1 AWS Account Preparation
```bash
# Verify AWS CLI and credentials
aws sts get-caller-identity
aws configure list

# Set deployment region (recommended: us-east-1 for full Bedrock support)
export AWS_DEFAULT_REGION=us-east-1
```

#### 1.2 Enable Required Services
```bash
# Enable Bedrock model access
aws bedrock put-model-invocation-logging-configuration \
  --logging-config '{"cloudWatchConfig":{"logGroupName":"bedrock-model-invocations","roleArn":"arn:aws:iam::ACCOUNT:role/service-role/AmazonBedrockExecutionRoleForKnowledgeBase"}}'

# Request model access (if not already done)
# This requires manual action in AWS Console
echo "⚠️  Manual step required: Enable Bedrock model access in AWS Console"
echo "   1. Go to Bedrock Console → Model access"
echo "   2. Request access for: Claude 3.5 Sonnet, Titan Embeddings"
```

#### 1.3 Install Dependencies
```bash
# Install CDK and dependencies
npm install -g aws-cdk
npm install
cd frontend && npm install && cd ..
cd lambda/chat-processor && npm install && cd ../..
cd lambda/actions && npm install && cd ../..
```

### Phase 2: Infrastructure Deployment (20 minutes)

#### 2.1 CDK Bootstrap
```bash
# Bootstrap CDK for the target account/region
cdk bootstrap aws://$(aws sts get-caller-identity --query Account --output text)/$AWS_DEFAULT_REGION
```

#### 2.2 Deploy Core Infrastructure
```bash
# Deploy the main stack
cdk deploy DevOpsKnowledgeOpsStack --require-approval never

# Capture outputs
aws cloudformation describe-stacks \
  --stack-name DevOpsKnowledgeOpsStack \
  --query 'Stacks[0].Outputs' > deployment-outputs.json
```

#### 2.3 Configure Bedrock Resources
```bash
# Run Bedrock setup script
./scripts/setup-bedrock-agent.sh

# Upload knowledge base content
./scripts/upload-knowledge-base.sh
```

### Phase 3: Application Deployment (15 minutes)

#### 3.1 Lambda Function Deployment
```bash
# Package and deploy Lambda functions
cd lambda/chat-processor
zip -r ../chat-processor.zip .
aws lambda update-function-code \
  --function-name devops-chat-processor \
  --zip-file fileb://../chat-processor.zip

cd ../actions
zip -r ../actions.zip .
aws lambda update-function-code \
  --function-name devops-actions-handler \
  --zip-file fileb://../actions.zip

cd ../session
zip -r ../session.zip .
aws lambda update-function-code \
  --function-name devops-session-handler \
  --zip-file fileb://../session.zip
```

#### 3.2 Frontend Deployment
```bash
# Build and deploy frontend
cd frontend

# Set environment variables from stack outputs
export REACT_APP_API_URL=$(jq -r '.[] | select(.OutputKey=="ApiGatewayUrl") | .OutputValue' ../deployment-outputs.json)
export REACT_APP_USER_POOL_ID=$(jq -r '.[] | select(.OutputKey=="UserPoolId") | .OutputValue' ../deployment-outputs.json)
export REACT_APP_USER_POOL_CLIENT_ID=$(jq -r '.[] | select(.OutputKey=="UserPoolClientId") | .OutputValue' ../deployment-outputs.json)

# Build production bundle
npm run build

# Deploy to S3 (if using S3 hosting)
aws s3 sync build/ s3://devops-knowledgeops-frontend-bucket --delete
```

### Phase 4: Production Configuration (10 minutes)

#### 4.1 CloudFront Distribution
```bash
# Create CloudFront distribution for frontend
aws cloudfront create-distribution --distribution-config file://cloudfront-config.json
```

#### 4.2 Custom Domain Setup (Optional)
```bash
# Create Route 53 hosted zone
aws route53 create-hosted-zone --name your-domain.com --caller-reference $(date +%s)

# Create SSL certificate
aws acm request-certificate --domain-name your-domain.com --validation-method DNS
```

#### 4.3 Environment Configuration
```bash
# Set production environment variables
aws lambda update-function-configuration \
  --function-name devops-chat-processor \
  --environment Variables='{
    "NODE_ENV":"production",
    "LOG_LEVEL":"info",
    "BEDROCK_AGENT_ID":"'$BEDROCK_AGENT_ID'",
    "BEDROCK_AGENT_ALIAS_ID":"'$BEDROCK_AGENT_ALIAS_ID'"
  }'
```

## 🔧 CI/CD Pipeline Setup

### GitHub Actions Workflow
```yaml
# .github/workflows/deploy.yml
name: Deploy DevOps KnowledgeOps Agent

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm ci
      - run: npm test
      - run: cd frontend && npm ci && npm test

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      - name: Deploy infrastructure
        run: |
          npm ci
          npm run build
          cdk deploy --require-approval never
      - name: Deploy Lambda functions
        run: ./scripts/deploy-lambdas.sh
      - name: Deploy frontend
        run: |
          cd frontend
          npm ci
          npm run build
          aws s3 sync build/ s3://${{ secrets.FRONTEND_BUCKET }} --delete
```

## 📊 Monitoring & Observability

### CloudWatch Setup
```bash
# Create custom dashboard
aws cloudwatch put-dashboard \
  --dashboard-name "DevOpsKnowledgeOpsAgent" \
  --dashboard-body file://monitoring/dashboard.json

# Set up alarms
aws cloudwatch put-metric-alarm \
  --alarm-name "HighLambdaErrors" \
  --alarm-description "High error rate in Lambda functions" \
  --metric-name Errors \
  --namespace AWS/Lambda \
  --statistic Sum \
  --period 300 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold
```

### X-Ray Tracing
```bash
# Enable X-Ray tracing for Lambda functions
aws lambda update-function-configuration \
  --function-name devops-chat-processor \
  --tracing-config Mode=Active
```

### Log Aggregation
```bash
# Create log groups with retention
aws logs create-log-group --log-group-name /aws/lambda/devops-chat-processor
aws logs put-retention-policy --log-group-name /aws/lambda/devops-chat-processor --retention-in-days 30
```

## 🔒 Security Configuration

### IAM Roles and Policies
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeAgent",
        "bedrock:InvokeModel"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "us-east-1"
        }
      }
    }
  ]
}
```

### API Gateway Security
```bash
# Enable API Gateway logging
aws apigateway update-stage \
  --rest-api-id $API_ID \
  --stage-name prod \
  --patch-ops op=replace,path=/accessLogSettings/destinationArn,value=$LOG_GROUP_ARN
```

### Cognito Security Settings
```bash
# Configure advanced security features
aws cognito-idp update-user-pool \
  --user-pool-id $USER_POOL_ID \
  --user-pool-add-ons AdvancedSecurityMode=ENFORCED
```

## 💰 Cost Optimization

### Resource Tagging
```bash
# Tag all resources for cost tracking
aws resourcegroupstaggingapi tag-resources \
  --resource-arn-list $LAMBDA_ARN \
  --tags Project=DevOpsKnowledgeOps,Environment=Production,Owner=DevOpsTeam
```

### Lambda Optimization
```bash
# Configure provisioned concurrency for consistent performance
aws lambda put-provisioned-concurrency-config \
  --function-name devops-chat-processor \
  --qualifier $LATEST \
  --provisioned-concurrency-config ProvisionedConcurrencyConfigs=1
```

### DynamoDB Optimization
```bash
# Enable auto-scaling for DynamoDB
aws application-autoscaling register-scalable-target \
  --service-namespace dynamodb \
  --resource-id table/devops-chat-sessions \
  --scalable-dimension dynamodb:table:ReadCapacityUnits \
  --min-capacity 1 \
  --max-capacity 10
```

## 🧪 Testing & Validation

### Deployment Validation
```bash
# Run deployment tests
./scripts/test-deployment.sh

# Health check
curl -f $API_URL/health

# End-to-end test
./scripts/e2e-test.sh
```

### Load Testing
```bash
# Install artillery for load testing
npm install -g artillery

# Run load test
artillery run tests/load-test.yml
```

## 🚀 Go-Live Checklist

### Pre-Launch
- [ ] All infrastructure deployed successfully
- [ ] Bedrock models accessible and tested
- [ ] Knowledge base populated and indexed
- [ ] Authentication working correctly
- [ ] API endpoints responding
- [ ] Frontend deployed and accessible
- [ ] Monitoring and alerting configured
- [ ] Security policies applied
- [ ] Load testing completed
- [ ] Backup and disaster recovery tested

### Launch
- [ ] DNS records updated (if using custom domain)
- [ ] SSL certificates validated
- [ ] CDN cache warmed
- [ ] User acceptance testing completed
- [ ] Documentation updated
- [ ] Team training completed

### Post-Launch
- [ ] Monitor metrics and logs
- [ ] Validate user feedback
- [ ] Performance optimization
- [ ] Cost monitoring
- [ ] Security audit

## 📞 Support & Maintenance

### Operational Runbooks
- **Incident Response**: `docs/runbooks/incident-response.md`
- **Scaling Procedures**: `docs/runbooks/scaling.md`
- **Backup & Recovery**: `docs/runbooks/backup-recovery.md`

### Maintenance Schedule
- **Daily**: Monitor metrics and logs
- **Weekly**: Review costs and performance
- **Monthly**: Security updates and patches
- **Quarterly**: Architecture review and optimization

## 🎯 Success Metrics

### Technical KPIs
- **Availability**: >99.9% uptime
- **Response Time**: <2s average API response
- **Error Rate**: <1% error rate
- **Cost**: <$500/month for moderate usage

### Business KPIs
- **User Adoption**: Active daily users
- **Query Success Rate**: Successful AI responses
- **User Satisfaction**: Feedback scores
- **Knowledge Base Utilization**: Query coverage

---

## 🎉 Ready for Production!

This deployment plan provides a comprehensive path to production for the DevOps KnowledgeOps Agent with:
- ✅ Scalable AWS infrastructure
- ✅ Production-ready security
- ✅ Comprehensive monitoring
- ✅ Cost optimization
- ✅ CI/CD automation
- ✅ Operational excellence