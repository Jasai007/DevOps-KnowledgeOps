# Fix API Gateway Authentication Configuration

## 🚨 Current Issues Identified

### 1. All Endpoints Require Authentication
- **Problem**: The `/auth` endpoint returns `403 Missing Authentication Token`
- **Root Cause**: API Gateway is configured to require authentication for ALL endpoints
- **Solution**: Make `/auth` endpoint public (no authentication required)

### 2. Invalid Authorization Header Format
- **Problem**: `403 Invalid key=value pair (missing equal-sign) in Authorization header`
- **Root Cause**: API Gateway expects a different authorization format than `Bearer <token>`
- **Current**: `Authorization: Bearer eyJraWQiOiJFMlJaWkFHOHo4WmhxUm...`
- **Expected**: Possibly AWS IAM signature or different format

### 3. Lambda Function Errors
- **Problem**: `502 Internal server error` for chat endpoint
- **Root Cause**: Lambda function is failing internally

## 🔧 Required Fixes

### Fix 1: Update API Gateway Resource Configuration

The CDK infrastructure needs to be updated to:

```typescript
// Authentication endpoint - should be PUBLIC
const authResource = api.root.addResource('auth');
authResource.addMethod('POST', new apigateway.LambdaIntegration(authLambda), {
  authorizationType: apigateway.AuthorizationType.NONE  // Make it public
});

// Protected endpoints - require Cognito authentication
const cognitoAuthorizer = new apigateway.CognitoUserPoolsAuthorizer(this, 'CognitoAuthorizer', {
  cognitoUserPools: [userPool]
});

const sessionResource = api.root.addResource('session');
sessionResource.addMethod('POST', new apigateway.LambdaIntegration(sessionLambda), {
  authorizationType: apigateway.AuthorizationType.COGNITO,
  authorizer: cognitoAuthorizer
});

const chatResource = api.root.addResource('chat');
chatResource.addMethod('POST', new apigateway.LambdaIntegration(chatLambda), {
  authorizationType: apigateway.AuthorizationType.COGNITO,
  authorizer: cognitoAuthorizer
});
```

### Fix 2: Update Lambda Functions to Handle Cognito Authorization

Lambda functions need to extract user info from the Cognito authorizer context:

```javascript
// In Lambda function
export const handler = async (event) => {
  // Get user info from Cognito authorizer
  const userInfo = event.requestContext.authorizer.claims;
  const userId = userInfo.sub;
  const email = userInfo.email;
  
  // Use userId for database queries
  // This ensures proper user isolation
};
```

### Fix 3: Frontend Authorization Header

The frontend should send the ID token (not access token) in the Authorization header:

```javascript
// Use ID token for API Gateway Cognito authorization
headers['Authorization'] = idToken; // Not Bearer + accessToken
```

## 🚀 Deployment Steps

### Step 1: Update CDK Infrastructure
```bash
cd infrastructure
# Update devops-knowledgeops-stack.ts with proper authorization
cdk diff
cdk deploy
```

### Step 2: Update Lambda Functions
```bash
cd lambda
# Update Lambda functions to handle Cognito context
npm run build
# Functions will be updated automatically on next CDK deploy
```

### Step 3: Update Frontend
```bash
# Update frontend to use ID token instead of access token
# Update API service authorization header format
```

## 🧪 Testing After Fixes

### Test 1: Public Auth Endpoint
```bash
curl -X POST https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/auth \
  -H "Content-Type: application/json" \
  -d '{"action":"signin","username":"demo@example.com","password":"DemoPassword123!"}'
```

### Test 2: Protected Endpoints with ID Token
```bash
curl -X POST https://66a22b8wlb.execute-api.us-east-1.amazonaws.com/prod/session \
  -H "Content-Type: application/json" \
  -H "Authorization: <ID_TOKEN>" \
  -d '{"action":"create"}'
```

## 📋 Current Working Credentials

After fixing the Cognito authentication:
- **Username**: `demo@example.com`
- **Password**: `DemoPassword123!`
- **Access Token**: Available (for Cognito API calls)
- **ID Token**: Available (for API Gateway authorization)

## 🎯 Expected Results After Fixes

1. ✅ `/auth` endpoint works without authentication
2. ✅ Protected endpoints work with ID token authorization
3. ✅ Proper user session isolation via Cognito user context
4. ✅ Chat functionality works end-to-end
5. ✅ Frontend can authenticate and use all features

The main issue is the API Gateway configuration - once we make the auth endpoint public and configure proper Cognito authorization for protected endpoints, the Lambda architecture will work correctly.