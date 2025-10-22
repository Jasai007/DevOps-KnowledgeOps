# Lambda Architecture Guide - DevOps KnowledgeOps

## 🎯 Why Use Lambda Architecture Instead of Express Server?

### **Current Issue with Express Server:**
- ❌ In-memory session storage (lost on restart)
- ❌ Manual session isolation implementation
- ❌ 403 Forbidden errors due to JWT parsing issues
- ❌ No scalability or high availability
- ❌ Manual infrastructure management

### **✅ Lambda Architecture Benefits:**
- ✅ **DynamoDB Storage** - Persistent, scalable session storage
- ✅ **Proper User Isolation** - Built-in Cognito integration
- ✅ **Serverless Scalability** - Auto-scaling, pay-per-use
- ✅ **AWS Native Integration** - Bedrock, S3, CloudWatch
- ✅ **Infrastructure as Code** - CDK deployment
- ✅ **No 403 Errors** - Proper authentication flow

## 🏗️ Lambda Architecture Components

### **1. Authentication Lambda (`lambda/auth/`)**
- Handles Cognito user authentication
- JWT token validation and user info extraction
- Secure session management

### **2. Session Lambda (`lambda/session/`)**
- DynamoDB-based session storage
- Proper user isolation with database queries
- Session CRUD operations with ownership validation

### **3. Chat Processor Lambda (`lambda/chat-processor/`)**
- Bedrock Agent integration
- Conversation memory and context management
- Message processing and storage

### **4. Actions Lambda (`lambda/actions/`)**
- DevOps tool integrations
- Infrastructure automation actions
- Knowledge base interactions

### **5. Infrastructure (CDK)**
- API Gateway with proper CORS
- DynamoDB tables with GSI for user queries
- Cognito User Pool and Client
- S3 bucket for knowledge base
- IAM roles and policies

## 🚀 Deployment Instructions

### **Prerequisites:**
```bash
# Install AWS CLI
# Download from: https://aws.amazon.com/cli/

# Install AWS CDK
npm install -g aws-cdk

# Configure AWS credentials
aws configure
```

### **Deploy Lambda Architecture:**
```powershell
# Run the deployment script
.\deploy-lambda-architecture.ps1
```

### **Manual Deployment Steps:**
```bash
# 1. Build Lambda functions
cd lambda
npm install
npm run build

# 2. Deploy infrastructure
cd ../infrastructure
npm install
cdk bootstrap
cdk deploy
```

## 🔧 Frontend Configuration

After deployment, update your frontend configuration:

### **1. Update API Base URL**
```typescript
// frontend/src/services/api.ts
const API_BASE_URL = 'https://your-api-gateway-url.amazonaws.com/prod';
```

### **2. Update Cognito Configuration**
```typescript
// Use the outputs from CDK deployment
const USER_POOL_ID = 'your-user-pool-id';
const USER_POOL_CLIENT_ID = 'your-client-id';
```

## 📊 API Endpoints (Lambda-based)

### **Authentication**
```
POST /auth
{
  "action": "signin",
  "username": "user@example.com",
  "password": "password"
}
```

### **Session Management**
```
POST /session
Authorization: Bearer <token>
{
  "action": "create" | "list" | "messages",
  "sessionId": "optional-session-id"
}
```

### **Chat Processing**
```
POST /chat
Authorization: Bearer <token>
{
  "message": "Your DevOps question",
  "sessionId": "optional-session-id"
}
```

## 🔍 Session Isolation in Lambda Architecture

### **How It Works:**
1. **User Authentication** - Cognito validates JWT tokens
2. **User ID Extraction** - Lambda extracts user info from token
3. **Database Queries** - DynamoDB queries filter by userId
4. **Ownership Validation** - Sessions are tied to specific users
5. **Automatic Isolation** - Database-level isolation prevents cross-user access

### **DynamoDB Schema:**
```
Table: devops-chat-sessions
Partition Key: sessionId (string)
Sort Key: messageId (string)

GSI: UserIndex
Partition Key: userId (string)
Sort Key: timestamp (number)

Sample Record:
{
  "sessionId": "session-123",
  "messageId": "SESSION_METADATA",
  "userId": "user@example.com",
  "createdAt": 1640995200000,
  "lastActivity": 1640995200000,
  "messageCount": 5
}
```

## 🛡️ Security Features

### **Authentication & Authorization:**
- Cognito JWT token validation
- User-specific database queries
- IAM role-based permissions
- API Gateway authentication

### **Data Isolation:**
- Database-level user isolation
- No shared in-memory state
- Encrypted data at rest (DynamoDB)
- VPC isolation (optional)

## 📈 Monitoring & Debugging

### **CloudWatch Logs:**
- Each Lambda function has separate log groups
- Structured logging with user context
- Error tracking and alerting

### **Metrics:**
- Request count and latency
- Error rates and success rates
- DynamoDB read/write metrics
- Bedrock API usage

### **Debug Endpoints:**
```
GET /health - Health check
POST /debug/sessions - List all sessions (dev only)
```

## 🔄 Migration from Express Server

### **Data Migration:**
1. Export existing sessions from Express server
2. Transform to DynamoDB format
3. Import using AWS CLI or Lambda function

### **Frontend Updates:**
1. Update API endpoints to use API Gateway URLs
2. Update authentication flow to use Cognito
3. Test session management with new Lambda endpoints

### **Testing:**
1. Test user authentication flow
2. Verify session isolation between users
3. Test chat functionality with Bedrock integration
4. Validate data persistence across deployments

## 🎯 Expected Results

After deploying Lambda architecture:

- ✅ **No more 403 Forbidden errors**
- ✅ **Proper user session isolation**
- ✅ **Persistent session storage**
- ✅ **Serverless scalability**
- ✅ **AWS native integration**
- ✅ **Infrastructure as Code**
- ✅ **Better security and compliance**
- ✅ **Cost-effective pay-per-use model**

## 🆘 Troubleshooting

### **Common Issues:**

1. **CDK Bootstrap Error:**
   ```bash
   cdk bootstrap aws://ACCOUNT-ID/REGION
   ```

2. **Lambda Build Fails:**
   ```bash
   cd lambda
   rm -rf node_modules
   npm install
   npm run build
   ```

3. **API Gateway CORS Issues:**
   - Check API Gateway CORS configuration
   - Verify OPTIONS method is enabled

4. **DynamoDB Access Denied:**
   - Check IAM role permissions
   - Verify table names in environment variables

The Lambda architecture provides a robust, scalable, and secure foundation for the DevOps KnowledgeOps application with proper user session isolation built-in at the database level.