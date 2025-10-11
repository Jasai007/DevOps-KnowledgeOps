# DevOps KnowledgeOps Agent

## Project Overview
An AI-powered DevOps assistant built with Amazon Bedrock AgentCore that provides expert-level DevOps guidance through an intuitive React chat interface.

## Technology Stack
- **Frontend**: React 18 with TypeScript, Material-UI (MUI)
- **Backend**: AWS Lambda functions (not included in Replit deployment)
- **AI Core**: Amazon Bedrock AgentCore with Strands integration
- **Deployment**: Replit autoscale deployment

## Current Setup
This Replit environment runs the React frontend application in development mode. The backend AWS infrastructure (Lambda, API Gateway, Bedrock, etc.) is deployed separately via AWS CDK.

## Running the Application

### Development Mode
The app runs automatically on port 5000 when you start the Replit. The workflow is configured to:
- Run the React development server
- Serve on `0.0.0.0:5000` for Replit proxy compatibility
- Enable hot reload for code changes

### Environment Configuration
- `PORT=5000` - Required for Replit
- `HOST=0.0.0.0` - Required for Replit proxy
- `WDS_SOCKET_HOST=0.0.0.0` - Required for webpack dev server

## Project Structure
```
├── frontend/           # React chat interface
│   ├── src/
│   │   ├── App.tsx    # Main chat application
│   │   ├── services/  # API service layer
│   │   └── index.tsx  # App entry point
│   ├── public/        # Static assets
│   └── package.json   # Frontend dependencies
├── lambda/            # AWS Lambda functions (backend)
├── infrastructure/    # AWS CDK infrastructure code
└── knowledge-base/    # DevOps documentation
```

## Features
- 🤖 AI-powered DevOps expert with comprehensive knowledge
- 💬 Real-time chat interface with syntax highlighting
- 🎨 Modern Material-UI design
- 📚 Built-in DevOps knowledge base covering:
  - Infrastructure as Code (Terraform, CloudFormation)
  - CI/CD Pipelines (GitHub Actions, Jenkins)
  - Container Orchestration (Kubernetes, Docker)
  - Monitoring & Observability
  - Security Best Practices

## Demo Mode
The frontend includes mock responses for demonstration purposes, allowing you to test the interface without connecting to the AWS backend.

## Deployment
The Replit deployment is configured for autoscale:
- Build: Compiles the React app to static files
- Run: Serves the built app using `serve` on port 5000

## AWS Backend (Not in Replit)
The full backend infrastructure requires:
- AWS account with Bedrock access
- CDK deployment (`npm run deploy` in root)
- Configuration of Bedrock Agent and Knowledge Base

See `DEPLOYMENT.md` for complete AWS setup instructions.

## Recent Changes
- Installed Node.js 20 and frontend dependencies
- Configured React dev server for Replit environment
- Set up workflow to run on port 5000
- Configured autoscale deployment
- Created TypeScript configuration for frontend

## Notes
- LSP errors in the editor are configuration-only issues that don't affect the running app
- The app uses webpack for building, which has its own TypeScript configuration
- Backend API calls will fail without AWS infrastructure (using mock data instead)
