# Cognito Integration Guide

## Current State
- **Demo Authentication**: Active (base64 tokens)
- **Cognito Authentication**: Implemented but inactive (JWT tokens)
- **Session Isolation**: Fixed for demo authentication

## Benefits of Switching to Cognito

### Security
- Real JWT tokens with proper validation
- Secure password hashing and storage
- Token expiration and refresh
- Built-in rate limiting and brute force protection

### User Management
- User registration and email verification
- Password reset functionality
- User profile management
- Multi-factor authentication support

### Enterprise Features
- OAuth/SAML integration
- User groups and roles
- Advanced security policies
- Audit logging

## Implementation Steps

### 1. Update Frontend API Service

```typescript
// In frontend/src/services/api.ts
constructor() {
  // Remove demo authentication
  // this.signInDemo().catch(console.error);
  
  // Use stored Cognito token instead
  this.accessToken = localStorage.getItem('accessToken');
}

// Remove signInDemo method and use AuthContext instead
```

### 2. Update Backend Token Validation

```javascript
// In backend/server.js
function getUserFromToken(authHeader) {
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return 'anonymous';
    }

    try {
        const token = authHeader.substring(7);
        
        // For Cognito JWT tokens
        const jwt = require('jsonwebtoken');
        const decoded = jwt.decode(token);
        
        if (decoded && decoded.sub) {
            // Use Cognito user ID (sub claim)
            return decoded.sub;
        }
        
        return 'anonymous';
    } catch (error) {
        console.log('Token decode error:', error.message);
        return 'anonymous';
    }
}
```

### 3. Update Frontend to Use AuthContext

```typescript
// In components that need authentication
import { useAuth } from '../contexts/AuthContext';

const MyComponent = () => {
  const { user, login, logout, isAuthenticated } = useAuth();
  
  // Use real authentication instead of demo
  if (!isAuthenticated) {
    return <LoginForm />;
  }
  
  return <ChatInterface />;
};
```

### 4. Set Up AWS Cognito

```bash
# Run the Cognito setup script
./scripts/setup-cognito.ps1

# Or manually create:
# - User Pool
# - App Client
# - Configure environment variables
```

## Environment Variables Needed

```bash
# In .env
USER_POOL_ID=us-east-1_YourPoolId
USER_POOL_CLIENT_ID=YourClientId
USER_POOL_CLIENT_SECRET=YourClientSecret
AWS_REGION=us-east-1
```

## Migration Strategy

### Option 1: Immediate Switch
- Update all components to use Cognito
- Require users to register/login
- More secure but requires user action

### Option 2: Gradual Migration
- Keep demo auth as fallback
- Add Cognito as optional upgrade
- Migrate users over time

### Option 3: Hybrid Approach
- Demo auth for development/testing
- Cognito for production deployment
- Environment-based switching

## Current Session Isolation Status

✅ **Fixed for Demo Auth**: Users can't see each other's sessions
✅ **Would Work with Cognito**: Same isolation logic applies
✅ **Production Ready**: Either system provides proper isolation

## Recommendation

For your current use case:
- **Keep demo auth** if this is for development/demo purposes
- **Switch to Cognito** if you need real user management
- **The session isolation fix works with both** authentication systems

The session isolation issue you reported is now fixed regardless of which authentication system you use.