# 🤖 Real AI Processing Configuration Guide

## 🎯 Overview
Your DevOps KnowledgeOps Agent is currently running in **demo mode** with intelligent mock responses. This guide shows you how to configure **real AI processing** using Amazon Bedrock AgentCore with Strands integration.

## 📋 What You Need in AWS

### 1. **Required AWS Services**
- ✅ **Amazon Bedrock** - Foundation models (Claude 3.5 Sonnet)
- ✅ **Bedrock Agents** - Agent orchestration with AgentCore
- ✅ **Bedrock Knowledge Bases** - RAG with your DevOps documentation
- ✅ **OpenSearch Serverless** - Vector database for embeddings
- ✅ **S3** - Document storage (already configured)
- ✅ **IAM** - Service roles and permissions (already configured)

### 2. **Model Access Requirements**
You need to request access to these models in Bedrock:
- **Anthropic Claude 3.5 Sonnet** - Main reasoning model
- **Amazon Titan Text Embeddings v2** - Document embeddings

### 3. **Regional Requirements**
- **Recommended**: `us-east-1` (N. Virginia) - Full feature availability
- **Alternative**: `us-west-2` (Oregon) - Full feature availability
- **Limited**: Other regions may have limited model selection

## 🚀 Quick Setup (Automated)

### Option 1: One-Command Setup (Linux/Mac)
```bash
# Make script executable and run
chmod +x scripts/setup-bedrock-agent.sh
./scripts/setup-bedrock-agent.sh
```

### Option 2: PowerShell Setup (Windows)
```powershell
# Run PowerShell script
.\scripts\setup-bedrock-agent.ps1
```

### Option 3: Manual Setup (AWS Console)
Follow the detailed guide in `docs/BEDROCK_SETUP.md`

## 🔧 Step-by-Step Configuration

### Step 1: Enable Model Access (5 minutes)
1. Go to [Amazon Bedrock Console](https://console.aws.amazon.com/bedrock/)
2. Navigate to **Model access** in the left sidebar
3. Click **Request model access**
4. Select these models:
   - ✅ **Anthropic Claude 3.5 Sonnet**
   - ✅ **Amazon Titan Text Embeddings v2**
5. Submit request (usually approved instantly)

### Step 2: Run Setup Script (15 minutes)
The automated script will create:
- **OpenSearch Serverless Collection** for vector storage
- **Bedrock Knowledge Base** with your DevOps docs
- **IAM Roles** with proper permissions
- **Data Source** connected to your S3 bucket

### Step 3: Create Bedrock Agent (10 minutes)
After running the script, create the agent in AWS Console:

1. Go to **Bedrock Console** → **Agents** → **Create Agent**
2. **Agent Details**:
   - **Name**: `DevOpsKnowledgeOpsAgent`
   - **Description**: `Expert DevOps assistant with comprehensive guidance`
   - **Foundation Model**: `Anthropic Claude 3.5 Sonnet`

3. **Agent Instructions** (copy from `lambda/bedrock/agent-config.ts`):
   ```
   You are an expert DevOps engineer and consultant with deep knowledge across all aspects of DevOps practices, tools, and methodologies...
   ```

4. **Add Knowledge Base**:
   - Select the knowledge base created by the script
   - **Instructions**: "Use this knowledge base to provide accurate DevOps guidance"

5. **Create Agent Alias**:
   - **Name**: `LIVE`
   - **Description**: `Production version`

### Step 4: Configure Environment Variables
After creating the agent, set these environment variables:

```bash
# From the setup script output
export BEDROCK_AGENT_ID=<your-agent-id>
export BEDROCK_AGENT_ALIAS_ID=<your-alias-id>
export KNOWLEDGE_BASE_ID=<your-kb-id>
```

### Step 5: Upload Knowledge Base (5 minutes)
```bash
# Upload your DevOps documentation
./scripts/upload-knowledge-base.sh
```

### Step 6: Test Configuration (2 minutes)
```bash
# Test the agent
./scripts/test-bedrock-agent.sh
```

## 💰 Cost Breakdown

### Bedrock Pricing (us-east-1)
- **Claude 3.5 Sonnet**: $3.00 per 1M input tokens, $15.00 per 1M output tokens
- **Titan Embeddings**: $0.0001 per 1K tokens
- **Agent Invocations**: $0.00025 per request

### Supporting Services
- **OpenSearch Serverless**: ~$0.24 per OCU-hour
- **S3 Storage**: ~$0.023 per GB/month
- **Lambda**: Already included in your deployment

### Monthly Estimates
- **Light Usage** (100 queries/day): **$15-25**
- **Moderate Usage** (1000 queries/day): **$75-150**
- **Heavy Usage** (10000 queries/day): **$300-600**

## 🎯 AgentCore & Strands Features

Your agent will have these advanced capabilities:

### **AgentCore Gateway**
- ✅ **Intelligent Routing** - Automatically routes queries to appropriate tools
- ✅ **Load Balancing** - Distributes requests across model instances
- ✅ **Request Optimization** - Optimizes prompts for better performance

### **AgentCore Memory**
- ✅ **Persistent Memory** - Maintains context across conversations
- ✅ **Contextual Recall** - Remembers previous interactions
- ✅ **Conversation Summary** - Automatically summarizes long conversations

### **Strands Integration**
- ✅ **Enhanced Reasoning** - Multi-step reasoning for complex problems
- ✅ **Tool Coordination** - Coordinates multiple tools and APIs
- ✅ **Contextual Memory** - Advanced memory management

## 🔍 Verification Steps

### 1. Check Model Access
```bash
aws bedrock list-foundation-models --region us-east-1 \
  --query 'modelSummaries[?contains(modelId, `claude`)]'
```

### 2. Test Knowledge Base
```bash
aws bedrock-agent-runtime retrieve \
  --knowledge-base-id <KB_ID> \
  --retrieval-query "Kubernetes troubleshooting" \
  --region us-east-1
```

### 3. Test Agent
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

#### **Model Access Denied**
- **Solution**: Request model access in Bedrock console
- **Wait Time**: Usually instant, can take up to 24 hours

#### **Agent Creation Failed**
- **Check**: IAM role permissions
- **Verify**: Foundation model availability in region

#### **Knowledge Base Ingestion Failed**
- **Check**: S3 bucket permissions
- **Verify**: Document format (Markdown, PDF, TXT)

#### **High Costs**
- **Monitor**: CloudWatch metrics for usage
- **Optimize**: Reduce token usage with better prompts
- **Limit**: Set up billing alerts

## 📞 Support Resources

### AWS Documentation
- [Amazon Bedrock User Guide](https://docs.aws.amazon.com/bedrock/)
- [Bedrock Agents Developer Guide](https://docs.aws.amazon.com/bedrock/latest/userguide/agents.html)
- [Knowledge Bases for Amazon Bedrock](https://docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base.html)

### Your Project Documentation
- `docs/BEDROCK_SETUP.md` - Detailed setup guide
- `docs/AWS_REQUIREMENTS.md` - Complete AWS requirements
- `docs/DEMO_GUIDE.md` - Demo scenarios and testing

## 🎉 What Changes After Setup

### **Before (Demo Mode)**
- ✅ Intelligent mock responses
- ✅ Professional UI experience
- ✅ Fast response times
- ❌ Limited to pre-written responses

### **After (Real AI)**
- ✅ **Real AI reasoning** with Claude 3.5 Sonnet
- ✅ **Dynamic responses** based on your knowledge base
- ✅ **Multi-step reasoning** for complex problems
- ✅ **Tool coordination** with AWS services
- ✅ **Contextual memory** across conversations
- ✅ **Continuous learning** from interactions

## 🚀 Ready to Go Live!

Your project is **already production-ready** in demo mode. Adding real AI processing gives you:

1. **Enhanced Intelligence** - Real reasoning capabilities
2. **Dynamic Knowledge** - Learns from your documentation
3. **Advanced Features** - AgentCore and Strands integration
4. **Scalable Architecture** - Handles production workloads

**Choose your path**:
- **Demo Mode**: Perfect for presentations and proof-of-concepts
- **Real AI**: Production-ready with advanced AI capabilities

Both modes provide an excellent user experience with your professional DevOps assistant!