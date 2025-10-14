# AWS Requirements for Real AI Processing

## 🎯 Overview
This document outlines all AWS services and configurations needed to enable real AI processing with Amazon Bedrock AgentCore and Strands integration.

## 📋 Required AWS Services

### 1. Core Services (Already Configured)
- ✅ **AWS Lambda** - Serverless compute for chat processing
- ✅ **Amazon API Gateway** - REST API endpoints
- ✅ **Amazon Cognito** - User authentication
- ✅ **Amazon DynamoDB** - Session and conversation storage
- ✅ **Amazon S3** - Knowledge base document storage
- ✅ **AWS IAM** - Identity and access management

### 2. AI/ML Services (Need Configuration)
- 🔧 **Amazon Bedrock** - Foundation models and AI agents
- 🔧 **Bedrock Agents** - Agent orchestration and management
- 🔧 **Bedrock Knowledge Bases** - Document retrieval and RAG
- 🔧 **Amazon OpenSearch Serverless** - Vector database for embeddings

## 🔐 Required Permissions

### Account-Level Requirements
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:*",
        "bedrock-agent:*",
        "bedrock-agent-runtime:*",
        "aoss:*",
        "opensearch:*"
      ],
      "Resource": "*"
    }
  ]
}
```

### Model Access Requirements
- **Anthropic Claude 3.5 Sonnet** - Main reasoning model
- **Amazon Titan Text Embeddings v2** - Document embeddings
- **Amazon Titan Multimodal Embeddings** - Multi-modal content

## 🌍 Regional Availability

### Recommended Regions
1. **us-east-1** (N. Virginia) - Full Bedrock feature availability
2. **us-west-2** (Oregon) - Full Bedrock feature availability
3. **eu-west-1** (Ireland) - Limited model selection

### Service Availability Check
```bash
# Check Bedrock availability
aws bedrock list-foundation-models --region us-east-1

# Check model access status
aws bedrock get-model-invocation-logging-configuration --region us-east-1
```

## 💰 Cost Estimates

### Bedrock Pricing (us-east-1)
- **Claude 3.5 Sonnet**: $3.00 per 1M input tokens, $15.00 per 1M output tokens
- **Titan Embeddings**: $0.0001 per 1K tokens
- **Agent Invocations**: $0.00025 per request

### Supporting Services
- **OpenSearch Serverless**: $0.24 per OCU-hour
- **S3 Storage**: $0.023 per GB/month
- **Lambda**: $0.20 per 1M requests
- **DynamoDB**: Pay-per-request pricing

### Monthly Cost Examples
- **Light Usage** (100 queries/day): $15-25
- **Moderate Usage** (1000 queries/day): $75-150
- **Heavy Usage** (10000 queries/day): $300-600

## 🚀 Setup Process

### Phase 1: Enable Model Access (5 minutes)
1. Go to Bedrock Console
2. Request model access for required models
3. Wait for approval (usually instant)

### Phase 2: Create Infrastructure (15 minutes)
```bash
# Run the automated setup script
./scripts/setup-bedrock-agent.sh
```

This script creates:
- OpenSearch Serverless collection
- Bedrock Knowledge Base
- Bedrock Agent with AgentCore features
- Required IAM roles and policies

### Phase 3: Upload Knowledge Base (5 minutes)
```bash
# Upload DevOps documentation
./scripts/upload-knowledge-base.sh
```

### Phase 4: Test Configuration (2 minutes)
```bash
# Test the agent
./scripts/test-bedrock-agent.sh
```

## 🔧 Manual Configuration (Alternative)

### 1. Create OpenSearch Collection
```bash
aws opensearchserverless create-collection \
  --name devops-knowledge-collection \
  --type VECTORSEARCH \
  --description "DevOps Knowledge Base Vector Store"
```

### 2. Create Knowledge Base
```bash
aws bedrock-agent create-knowledge-base \
  --name "DevOpsKnowledgeBase" \
  --description "Comprehensive DevOps documentation" \
  --role-arn "arn:aws:iam::ACCOUNT:role/BedrockKnowledgeBaseRole" \
  --knowledge-base-configuration file://kb-config.json \
  --storage-configuration file://storage-config.json
```

### 3. Create Bedrock Agent
```bash
aws bedrock-agent create-agent \
  --agent-name "DevOpsKnowledgeOpsAgent" \
  --foundation-model "anthropic.claude-3-5-sonnet-20241022-v2:0" \
  --instruction "$(cat agent-instructions.txt)"
```

## 🎯 AgentCore & Strands Features

### AgentCore Gateway
- **Intelligent Routing**: Automatically routes queries to appropriate tools
- **Load Balancing**: Distributes requests across multiple model instances
- **Request Optimization**: Optimizes prompts for better performance

### AgentCore Memory
- **Persistent Memory**: Maintains context across conversations
- **Contextual Recall**: Remembers previous interactions
- **Conversation Summary**: Automatically summarizes long conversations

### Strands Integration
- **Enhanced Reasoning**: Multi-step reasoning for complex problems
- **Tool Coordination**: Coordinates multiple tools and APIs
- **Contextual Memory**: Advanced memory management

## 🔍 Verification Steps

### 1. Check Model Access
```bash
aws bedrock list-foundation-models --region us-east-1 \
  --query 'modelSummaries[?contains(modelId, `claude`)]'
```

### 2. Verify Agent Status
```bash
aws bedrock-agent get-agent --agent-id <AGENT_ID> --region us-east-1
```

### 3. Test Knowledge Base
```bash
aws bedrock-agent-runtime retrieve \
  --knowledge-base-id <KB_ID> \
  --retrieval-query "Kubernetes troubleshooting" \
  --region us-east-1
```

### 4. Test Agent Invocation
```bash
aws bedrock-agent-runtime invoke-agent \
  --agent-id <AGENT_ID> \
  --agent-alias-id <ALIAS_ID> \
  --session-id "test-session" \
  --input-text "Help me with EKS troubleshooting" \
  --region us-east-1
```

## 🚨 Troubleshooting

### Common Issues

#### Model Access Denied
- **Solution**: Request model access in Bedrock console
- **Wait Time**: Usually instant, can take up to 24 hours

#### Agent Creation Failed
- **Check**: IAM role permissions
- **Verify**: Foundation model availability in region

#### Knowledge Base Ingestion Failed
- **Check**: S3 bucket permissions
- **Verify**: Document format (Markdown, PDF, TXT)

#### High Costs
- **Monitor**: CloudWatch metrics for usage
- **Optimize**: Reduce token usage with better prompts
- **Limit**: Set up billing alerts

## 📞 Support Resources

### AWS Documentation
- [Amazon Bedrock User Guide](https://docs.aws.amazon.com/bedrock/)
- [Bedrock Agents Developer Guide](https://docs.aws.amazon.com/bedrock/latest/userguide/agents.html)
- [Knowledge Bases for Amazon Bedrock](https://docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base.html)

### Pricing Information
- [Amazon Bedrock Pricing](https://aws.amazon.com/bedrock/pricing/)
- [OpenSearch Serverless Pricing](https://aws.amazon.com/opensearch-service/pricing/)

### Community Support
- [AWS re:Post Bedrock Forum](https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-bedrock)
- [AWS Bedrock GitHub Samples](https://github.com/aws-samples/amazon-bedrock-samples)

---

## 🎉 Ready for Production AI!

Once you complete these steps, your DevOps KnowledgeOps Agent will have:
- ✅ Real AI processing with Claude 3.5 Sonnet
- ✅ Comprehensive DevOps knowledge base
- ✅ Advanced reasoning capabilities
- ✅ Tool coordination and memory
- ✅ Production-ready scalability