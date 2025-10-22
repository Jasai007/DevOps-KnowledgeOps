# DevOps KnowledgeOps Agent - Deployment Guide

## 🚀 Quick Start

### Prerequisites
- AWS CLI configured with appropriate permissions
- Node.js 18+ and npm
- AWS CDK CLI (`npm install -g aws-cdk`)

### One-Command Deployment
```bash
# Make deployment script executable (Linux/Mac)
chmod +x scripts/deploy.sh

# Run deployment
./scripts/deploy.sh
```

### Manual Deployment Steps

#### 1. Install Dependencies
```bash
npm install
```

#### 2. Bootstrap CDK
```bash
cdk bootstrap
```

#### 3. Deploy Infrastructure
```bash
cdk deploy
```

#### 4. Upload Knowledge Base
```bash
cd scripts
export KNOWLEDGE_BUCKET_NAME=<your-bucket-name>
npm run upload-kb
cd ..
```

#### 5. Build Frontend
```bash
cd frontend
npm install
export REACT_APP_API_URL=<your-api-gateway-url>
npm run build
cd ..
```

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│   React App     │───▶│   API Gateway    │───▶│   Lambda Functions  │
│   (Frontend)    │    │                  │    │                     │
└─────────────────┘    └──────────────────┘    └─────────────────────┘
                                                          │
                       ┌──────────────────┐              │
                       │   Cognito        │◀─────────────┘
                       │   (Auth)         │
                       └──────────────────┘
                                                          │
┌─────────────────┐    ┌──────────────────┐              │
│   S3 Bucket     │───▶│   Bedrock        │◀─────────────┘
│   (Knowledge)   │    │   AgentCore      │
└─────────────────┘    │   + Strands      │
                       └──────────────────┘
                                │
                       ┌──────────────────┐
                       │   DynamoDB       │
                       │   (Sessions)     │
                       └──────────────────┘
```

## 📋 Components Deployed

### Infrastructure (CDK)
- **API Gateway**: REST API with CORS support
- **Lambda Functions**: Auth, Session, Chat, Actions
- **Cognito**: User Pool and Identity Pool
- **DynamoDB**: Chat sessions and conversation memory
- **S3**: Knowledge base document storage
- **IAM Roles**: Least privilege access policies

### Lambda Functions
1. **Auth Handler**: User authentication and demo user creation
2. **Session Manager**: Conversation session management
3. **Chat Processor**: Main chat logic with Bedrock integration
4. **Actions Handler**: DevOps tool integrations and AWS actions

### Frontend Application
- **React**: Modern, responsive chat interface
- **Material-UI**: Professional design system
- **Syntax Highlighting**: Code formatting with Prism
- **Real-time Chat**: Smooth user experience

## 🔧 Configuration

### Environment Variables
```bash
# Required for Bedrock Agent (optional for demo)
export BEDROCK_AGENT_ID=<agent-id>
export BEDROCK_AGENT_ALIAS_ID=<alias-id>

# AWS Configuration
export AWS_REGION=us-east-1
export AWS_ACCOUNT_ID=<your-account-id>

# Knowledge Base
export KNOWLEDGE_BUCKET_NAME=<bucket-name>
```

### Demo Mode
The application works in demo mode with mock responses even without a configured Bedrock Agent. This ensures smooth demonstrations while the full agent setup is optional.

## 🎯 Demo Scenarios

### Ready-to-Use Queries
1. **Kubernetes Troubleshooting**
   - "My EKS cluster pods are failing to start with ImagePullBackOff errors"

2. **Infrastructure as Code**
   - "What are the best practices for organizing Terraform code?"

3. **CI/CD Pipeline Design**
   - "Design a CI/CD pipeline for microservices using GitHub Actions"

4. **Monitoring Setup**
   - "What monitoring stack would you recommend for containerized applications?"

5. **Security Implementation**
   - "How do I implement security scanning in my DevOps pipeline?"

## 🛠️ Advanced Setup (Optional)

### Full Bedrock Agent Setup
```bash
# Set up complete Bedrock Agent with Knowledge Base
cd scripts
npm run setup-agent
```

### Custom Knowledge Base
1. Add your documents to `knowledge-base/` directory
2. Run the upload script: `npm run upload-kb`
3. Documents are automatically processed and embedded

### Action Groups Integration
The system includes pre-built action groups for:
- Terraform syntax validation
- Kubernetes manifest generation
- Dockerfile analysis
- CI/CD pipeline generation
- AWS service integration (CloudWatch, EKS)

## 📊 Monitoring and Logs

### CloudWatch Logs
- `/aws/lambda/devops-auth-handler`
- `/aws/lambda/devops-session-handler`
- `/aws/lambda/devops-chat-processor`
- `/aws/lambda/devops-actions-handler`

### API Gateway Metrics
- Request count and latency
- Error rates and status codes
- Integration performance

### DynamoDB Metrics
- Read/write capacity utilization
- Throttling events
- Item counts

## 🔒 Security Features

### Authentication
- AWS Cognito User Pool
- JWT token-based authentication
- Demo user for quick testing

### Authorization
- IAM roles with least privilege
- Resource-based access control
- API Gateway authentication

### Data Protection
- Encryption at rest (DynamoDB, S3)
- Encryption in transit (HTTPS/TLS)
- No sensitive data in logs

## 💰 Cost Optimization

### Serverless Architecture
- Pay-per-use Lambda functions
- On-demand DynamoDB billing
- S3 standard storage class

### Estimated Costs (Monthly)
- **Light Usage** (100 requests/day): ~$5-10
- **Moderate Usage** (1000 requests/day): ~$20-40
- **Heavy Usage** (10000 requests/day): ~$100-200

*Costs vary based on Bedrock usage, which is the primary cost driver*

## 🚨 Troubleshooting

### Common Issues

#### 1. CDK Bootstrap Error
```bash
# Solution: Bootstrap with explicit account/region
cdk bootstrap aws://ACCOUNT-ID/REGION
```

#### 2. Lambda Permission Errors
```bash
# Check IAM roles have necessary permissions
aws iam get-role --role-name DevOpsKnowledgeOpsStack-DevOpsLambdaRole
```

#### 3. Frontend API Connection
```bash
# Verify API Gateway URL in frontend environment
echo $REACT_APP_API_URL
```

#### 4. Knowledge Base Upload Fails
```bash
# Check S3 bucket permissions and existence
aws s3 ls s3://your-bucket-name
```

### Debug Commands
```bash
# Check stack status
aws cloudformation describe-stacks --stack-name DevOpsKnowledgeOpsStack

# Test API endpoints
curl -X POST https://your-api-url/health

# Check Lambda logs
aws logs tail /aws/lambda/devops-chat-processor --follow
```

## 🎉 Success Validation

### Deployment Checklist
- [ ] CDK stack deployed successfully
- [ ] All Lambda functions created
- [ ] API Gateway endpoints responding
- [ ] Cognito User Pool configured
- [ ] DynamoDB tables created
- [ ] S3 bucket accessible
- [ ] Knowledge base uploaded
- [ ] Frontend built and accessible
- [ ] Demo user created
- [ ] Sample queries working

### Test Commands
```bash
# Test health endpoint
curl https://your-api-url/health

# Test authentication
curl -X POST https://your-api-url/auth \
  -H "Content-Type: application/json" \
  -d '{"action":"create-demo-user"}'

# Test chat (with demo user)
curl -X POST https://your-api-url/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello, can you help me with Kubernetes?"}'
```

## 📞 Support

### Documentation
- [Architecture Guide](docs/ARCHITECTURE.md)
- [Demo Guide](docs/DEMO_GUIDE.md)
- [API Documentation](docs/API.md)

### Common Resources
- [AWS Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [CDK Documentation](https://docs.aws.amazon.com/cdk/)
- [React Documentation](https://reactjs.org/docs/)

---

**🎯 Ready for Demo!** Your DevOps KnowledgeOps Agent is now deployed and ready to showcase the power of Bedrock AgentCore with Strands integration!