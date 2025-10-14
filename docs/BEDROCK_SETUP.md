# Amazon Bedrock Agent Setup Guide

## 🎯 Overview
This guide walks you through setting up a real Amazon Bedrock Agent with AgentCore and Strands integration for production AI processing.

## 📋 AWS Prerequisites

### 1. AWS Account Requirements
- **AWS Account** with administrative access
- **Region**: us-east-1 (recommended for Bedrock availability)
- **Bedrock Model Access**: Request access to Claude 3.5 Sonnet

### 2. Required AWS Services
- ✅ **Amazon Bedrock** - AI foundation models
- ✅ **Bedrock Agents** - Agent orchestration
- ✅ **Bedrock Knowledge Bases** - Document retrieval
- ✅ **OpenSearch Serverless** - Vector database for embeddings
- ✅ **S3** - Knowledge base document storage
- ✅ **IAM** - Service roles and permissions
- ✅ **Lambda** - Already configured in your project
- ✅ **API Gateway** - Already configured in your project

## 🔧 Step-by-Step Setup

### Step 1: Enable Bedrock Model Access

1. **Go to Amazon Bedrock Console**
   ```
   https://console.aws.amazon.com/bedrock/
   ```

2. **Request Model Access**
   - Navigate to **Model access** in the left sidebar
   - Click **Request model access**
   - Select these models:
     - ✅ **Anthropic Claude 3.5 Sonnet**
     - ✅ **Amazon Titan Text Embeddings v2**
     - ✅ **Amazon Titan Multimodal Embeddings G1**

3. **Wait for Approval** (usually instant for most models)

### Step 2: Create Knowledge Base

1. **Create OpenSearch Serverless Collection**
   ```bash
   aws opensearchserverless create-collection \
     --name devops-knowledge-collection \
     --type VECTORSEARCH \
     --description "DevOps Knowledge Base Vector Store"
   ```

2. **Create Knowledge Base**
   - Go to **Bedrock Console** → **Knowledge bases**
   - Click **Create knowledge base**
   - **Name**: `DevOpsKnowledgeBase`
   - **Description**: `Comprehensive DevOps documentation and best practices`
   - **IAM Role**: Create new service role
   - **Data source**: S3 (use the bucket from your CDK deployment)
   - **Embeddings model**: Amazon Titan Text Embeddings v2
   - **Vector database**: OpenSearch Serverless collection created above

### Step 3: Create Bedrock Agent

1. **Create Agent**
   - Go to **Bedrock Console** → **Agents**
   - Click **Create Agent**
   - **Agent name**: `DevOpsKnowledgeOpsAgent`
   - **Description**: `Expert DevOps assistant with comprehensive guidance`
   - **Foundation model**: Anthropic Claude 3.5 Sonnet
   - **Instructions**: Use the detailed prompt from your agent-config.ts

2. **Add Knowledge Base**
   - In the agent configuration
   - Click **Add knowledge base**
   - Select the knowledge base created in Step 2
   - **Instructions**: "Use this knowledge base to provide accurate DevOps guidance"

3. **Create Action Groups** (Optional but recommended)
   - **AWS Integration Actions**
   - **Terraform Validation Actions**
   - **Kubernetes Manifest Generation**

### Step 4: Configure Action Groups

1. **Create Lambda Functions for Actions** (already in your project)
   - Your `lambda/actions/action-handler.ts` is ready
   - Supports AWS service integration
   - Terraform syntax validation
   - Kubernetes manifest generation

2. **Add Action Groups to Agent**
   - **Name**: `DevOpsActions`
   - **Description**: `DevOps tool integrations and validations`
   - **Lambda function**: Use your deployed actions Lambda
   - **API Schema**: Define the available actions

## 🛠️ Implementation Scripts

### Create Bedrock Setup Script