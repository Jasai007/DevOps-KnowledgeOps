# DevOps KnowledgeOps Backend

Express.js server providing API endpoints for the DevOps KnowledgeOps Agent, featuring direct integration with Amazon Bedrock AgentCore for AI-powered DevOps assistance.

## Overview

This backend serves as the API layer between the React frontend and AWS services, including Bedrock AgentCore for AI responses, Cognito for authentication, and DynamoDB for session management.

## Features

- **AgentCore Integration**: Direct connection to Amazon Bedrock AgentCore for AI responses
- **Authentication**: AWS Cognito integration for secure user management
- **Session Management**: DynamoDB-based session handling with user isolation
- **CORS Support**: Configured for frontend communication
- **Health Monitoring**: Built-in health check endpoints
- **TypeScript**: Full TypeScript support for type safety

## Technology Stack

- **Node.js**: Runtime environment
- **Express.js**: Web framework for API endpoints
- **TypeScript**: Type-safe development
- **AWS SDK v3**: Modern AWS service integration
- **CORS**: Cross-origin resource sharing
- **UUID**: Unique identifier generation
- **JWT**: JSON Web Token handling

## Project Structure

```
backend/
├── server.js              # Main Express server entry point
├── agentcore-gateway.js   # AgentCore integration logic
├── package.json           # Dependencies and scripts
├── tsconfig.json          # TypeScript configuration
├── config/                # Configuration files
│   ├── cognito-config.env # Cognito configuration
│   ├── kb-config-s3.json  # S3 knowledge base config
│   └── kb-config.json     # Knowledge base configuration
└── README.md             # This file
```

## Local Development

### Prerequisites

- Node.js 18+ and npm
- AWS CLI configured with appropriate permissions
- Cognito User Pool and Bedrock AgentCore setup

### Setup

1. **Install dependencies**:
   ```bash
   cd backend
   npm install
   ```

2. **Configure environment**:
   Copy and update configuration files:
   ```bash
   cp config/cognito-config.env .env
   # Edit .env with your AWS credentials and configuration
   ```

3. **Start development server**:
   ```bash
   npm run dev
   ```

   The server will start on port 3001 with nodemon for auto-restart.

4. **Production start**:
   ```bash
   npm start
   ```

### Available Scripts

- `npm start`: Start production server
- `npm run dev`: Start development server with nodemon
- `npm run build`: Compile TypeScript (if using TS files)
- `npm test`: Run test suite

## API Endpoints

### Authentication Endpoints
- `POST /api/auth/login`: User login
- `POST /api/auth/signup`: User registration
- `POST /api/auth/verify`: Token verification

### Chat Endpoints
- `POST /api/chat`: Send chat message to AgentCore
- `GET /api/chat/history`: Get chat history (if enabled)

### System Endpoints
- `GET /api/health`: Health check endpoint

## Configuration

### Environment Variables (.env)

```env
# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key

# Cognito Configuration
COGNITO_USER_POOL_ID=your-user-pool-id
COGNITO_CLIENT_ID=your-client-id
COGNITO_REGION=us-east-1

# AgentCore Configuration
AGENTCORE_AGENT_ID=your-agent-id
AGENTCORE_ALIAS_ID=your-alias-id

# Server Configuration
PORT=3001
NODE_ENV=development
```

### Knowledge Base Configuration

The backend integrates with AWS Bedrock Knowledge Bases stored in S3. Configuration files in `config/` define:
- Knowledge base IDs
- S3 bucket locations
- Vector store settings

## AgentCore Integration

The `agentcore-gateway.js` file handles:
- Direct AgentCore API calls
- Request/response formatting
- Error handling and retries
- Session management
- Response streaming (if configured)

## Authentication Flow

1. User authenticates via Cognito
2. JWT token issued and validated
3. Session created in DynamoDB
4. Subsequent requests include auth headers
5. AgentCore responses filtered by user context

## Deployment

### Local Testing

1. **Start the server**:
   ```bash
   npm start
   ```

2. **Test endpoints**:
   ```bash
   curl -X GET http://localhost:3001/api/health
   ```

### Production Deployment

The backend can be deployed as:
- **AWS Lambda**: Serverless function
- **EC2 Instance**: Traditional server
- **ECS/Fargate**: Containerized deployment
- **Elastic Beanstalk**: Managed platform

### Docker Support

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3001
CMD ["npm", "start"]
```

## Monitoring and Logging

- **Health Checks**: `/api/health` endpoint for load balancer monitoring
- **Error Logging**: Console logging with structured error messages
- **AWS CloudWatch**: Integration for production monitoring
- **Request Tracing**: Correlation IDs for debugging

## Security Considerations

- **CORS**: Configured for specific origins
- **Input Validation**: Request sanitization
- **Rate Limiting**: Implemented at API Gateway level
- **Secrets Management**: AWS Secrets Manager integration
- **HTTPS Only**: SSL/TLS encryption required

## Troubleshooting

### Common Issues

- **AgentCore Connection**: Verify agent ID and permissions
- **Cognito Errors**: Check user pool configuration
- **CORS Issues**: Update allowed origins in server.js
- **Session Errors**: Verify DynamoDB table and permissions

### Debug Mode

Enable detailed logging:
```bash
DEBUG=* npm run dev
```

### Testing

Run the test suite:
```bash
npm test
```

## Contributing

1. Follow TypeScript conventions
2. Add proper error handling
3. Update API documentation for new endpoints
4. Test authentication flows thoroughly

## Dependencies

### Runtime Dependencies
- `express`: Web framework
- `cors`: CORS middleware
- `uuid`: ID generation
- `jsonwebtoken`: JWT handling
- `aws-sdk/*`: AWS service clients

### Development Dependencies
- `nodemon`: Development auto-restart
- `@types/*`: TypeScript definitions
- `typescript`: TypeScript compiler
