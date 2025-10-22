# DevOps KnowledgeOps Agent

A clean, simplified AI-powered DevOps assistant built with Amazon Bedrock AgentCore that provides expert-level DevOps guidance without the complexity of chat history storage.

## Features

- **Pure AgentCore Integration**: Direct integration with Bedrock AgentCore for immediate responses
- **DevOps Expertise**: Comprehensive knowledge covering Infrastructure as Code, CI/CD, containers, monitoring, and security
- **Clean Chat Interface**: Modern React interface focused on current conversation
- **AWS Cognito Authentication**: Secure user authentication without session complexity
- **Multi-cloud Support**: Guidance for AWS, Azure, GCP, and hybrid environments

## Architecture

Simplified serverless architecture:
- **Frontend**: React chat interface with direct API calls
- **Backend**: Clean Express.js server with AgentCore Gateway
- **AI Core**: Direct Bedrock AgentCore integration
- **Authentication**: AWS Cognito for user management
- **No History**: Stateless conversations focused on current queries

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