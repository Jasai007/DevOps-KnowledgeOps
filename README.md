# DevOps KnowledgeOps Agent

An AI-powered DevOps assistant built with Amazon Bedrock AgentCore that provides expert-level DevOps guidance through an intuitive chat interface.

## Features

- **Bedrock AgentCore Integration**: Leverages AgentCore Gateway, Memory, and Strands Agent for enhanced reasoning
- **DevOps Expertise**: Comprehensive knowledge base covering Infrastructure as Code, CI/CD, containers, monitoring, and security
- **Real-time Chat**: Modern React interface with syntax highlighting and live responses
- **AWS Integration**: Secure access to AWS services with role-based permissions
- **Multi-cloud Support**: Guidance for AWS, Azure, GCP, and hybrid environments

## Architecture

The system uses a serverless architecture with:
- **Frontend**: React chat interface with real-time WebSocket communication
- **Backend**: AWS Lambda functions orchestrated by API Gateway
- **AI Core**: Bedrock AgentCore with Strands integration for enhanced reasoning
- **Knowledge**: S3-based knowledge base with vector search capabilities
- **Authentication**: AWS Cognito for user management and session persistence

## Quick Start

### Prerequisites

- AWS CLI configured with appropriate permissions
- Node.js 18+ and npm
- AWS CDK CLI installed (`npm install -g aws-cdk`)

### Deployment

1. **Install dependencies**:
   ```bash
   npm install
   ```

2. **Bootstrap CDK** (first time only):
   ```bash
   cdk bootstrap
   ```

3. **Deploy infrastructure**:
   ```bash
   npm run deploy
   ```

4. **Note the outputs** - you'll need the API Gateway URL and Cognito details for the frontend.

### Development

- **Build**: `npm run build`
- **Watch**: `npm run watch`
- **Test**: `npm run test`

## Project Structure

```
├── infrastructure/          # AWS CDK infrastructure code
│   ├── app.ts              # CDK app entry point
│   └── devops-knowledgeops-stack.ts  # Main stack definition
├── lambda/                 # Lambda function code
├── frontend/               # React chat interface
├── knowledge-base/         # DevOps documentation and content
└── docs/                   # Additional documentation
```

## Configuration

Environment variables:
- `AWS_REGION`: AWS region for deployment (default: us-east-1)
- `AWS_ACCOUNT_ID`: AWS account ID for deployment

## Demo Scenarios

The agent excels at:
- Infrastructure troubleshooting and optimization
- CI/CD pipeline design and debugging
- Container orchestration guidance
- Security best practices and compliance
- Multi-cloud architecture recommendations
- Automation and scripting assistance

## Contributing

This is a hackathon project focused on demonstrating the power of Bedrock AgentCore for DevOps use cases.

## License

MIT License - see LICENSE file for details.