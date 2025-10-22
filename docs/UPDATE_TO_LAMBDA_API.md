# Update Frontend to Use Lambda API

## 🎯 Current Situation

### **✅ What's Deployed:**
- **Lambda Functions**: `agentcore-simple-chat`, `cors-auth-final`
- **API Gateway**: `https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod`
- **DynamoDB Tables**: `devops-chat-sessions`, `devops-agent-memory`
- **Bedrock Agent**: `MNJESZYALW` with alias `TSTALIASID`

### **❌ Current Problem:**
- Frontend is calling `localhost:3001` (Express server)
- Should be calling Lambda API Gateway endpoints
- Lambda API provides proper user isolation with DynamoDB

## 🔧 Frontend Configuration Update

### **1. Update API Base URL**

Update `frontend/src/services/api.ts`:

```typescript
// Change from:
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:3001';

// To:
const API_BASE_URL = process.env.REACT_APP_API_URL || 'https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod';
```

### **2. Update Environment Variables**

Create/update `.env` file in frontend:
```env
REACT_APP_API_URL=https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod
REACT_APP_USER_POOL_ID=us-east-1_QVdUR725D
REACT_APP_USER_POOL_CLIENT_ID=7a283i8pqhq7h1k88me51gsefo
```

### **3. Test Lambda API Endpoints**

The Lambda API provides these endpoints:
- `POST /auth` - Authentication
- `POST /session` - Session management  
- `POST /chat` - Chat processing
- `POST /actions` - DevOps actions

## 🚀 Benefits of Using Lambda API

### **✅ Proper User Isolation:**
- **DynamoDB Storage** - Sessions stored in database with userId
- **Database Queries** - `SELECT * FROM sessions WHERE userId = ?`
- **No Cross-User Access** - Database-level isolation
- **Persistent Storage** - Sessions survive server restarts

### **✅ Better Architecture:**
- **Serverless Scalability** - Auto-scaling based on demand
- **Cost Efficiency** - Pay only for actual usage
- **AWS Integration** - Native Bedrock, Cognito, S3 integration
- **High Availability** - Multi-AZ deployment

### **✅ No More 403 Errors:**
- **Proper Authentication** - Cognito JWT validation
- **Consistent User IDs** - Database-stored user associations
- **Session Ownership** - Clear ownership model in database

## 🔧 Implementation Steps

### **Step 1: Update Frontend API Configuration**
```bash
# Update the API service to use Lambda endpoints
# File: frontend/src/services/api.ts
```

### **Step 2: Test Lambda Endpoints**
```bash
# Test the Lambda API
node test-lambda-api.js
```

### **Step 3: Update Authentication Flow**
```bash
# Ensure Cognito configuration matches Lambda environment
```

### **Step 4: Deploy Frontend Changes**
```bash
# Build and deploy frontend with new API configuration
npm run build
```

## 📊 Expected Results

### **After Switching to Lambda API:**
- ✅ **Proper User Isolation** - Each user sees only their sessions
- ✅ **No 403 Errors** - Proper Cognito authentication
- ✅ **Persistent Sessions** - DynamoDB storage
- ✅ **Better Performance** - Serverless scaling
- ✅ **Cost Efficiency** - Pay-per-use model

### **Session Management:**
```javascript
// Lambda API automatically provides:
// - User-specific session queries
// - Database-level isolation
// - Proper ownership validation
// - Persistent storage
```

## 🛠️ Quick Fix Script

Create this script to update frontend configuration:

```javascript
// update-frontend-config.js
const fs = require('fs');

// Update API service
const apiServicePath = 'frontend/src/services/api.ts';
let apiService = fs.readFileSync(apiServicePath, 'utf8');

apiService = apiService.replace(
  /const API_BASE_URL = .*/,
  "const API_BASE_URL = process.env.REACT_APP_API_URL || 'https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod';"
);

fs.writeFileSync(apiServicePath, apiService);
console.log('✅ Updated API service to use Lambda endpoints');

// Create .env file
const envContent = `REACT_APP_API_URL=https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod
REACT_APP_USER_POOL_ID=us-east-1_QVdUR725D
REACT_APP_USER_POOL_CLIENT_ID=7a283i8pqhq7h1k88me51gsefo`;

fs.writeFileSync('frontend/.env', envContent);
console.log('✅ Created frontend .env file');
```

## 🎯 Why This Solves the Session Isolation Issue

### **Database-Level Isolation:**
```sql
-- Lambda API uses proper database queries:
SELECT * FROM devops-chat-sessions 
WHERE userId = 'user@example.com' 
AND messageId = 'SESSION_METADATA';

-- Instead of in-memory filtering that can fail
```

### **Proper Authentication:**
```javascript
// Lambda validates JWT tokens properly:
const userInfo = await cognitoHelper.getUserInfo(accessToken);
// Consistent user identification across requests
```

### **No Shared State:**
- Each Lambda invocation is isolated
- No shared in-memory session storage
- Database provides consistent state

The Lambda architecture is the **proper solution** for user session isolation and eliminates all the 403 Forbidden errors we've been experiencing with the Express server.