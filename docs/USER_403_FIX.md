# Fix for 403 Forbidden Errors - User Session Access

## Problem
After implementing user session isolation, legitimate users are getting 403 Forbidden errors when trying to access their own chat sessions. Only the demo user can successfully query the system.

## Root Cause
The JWT token parsing function is not correctly extracting user identifiers from real Cognito JWT tokens, causing the system to treat legitimate users as unauthorized.

## Immediate Fix Applied

### 1. Enhanced JWT Token Parsing with Debugging
Added comprehensive debugging to the `getUserIdFromToken` function:

```javascript
// Enhanced token parsing with fallback mechanisms
function getUserIdFromToken(authHeader) {
  // ... detailed logging and multiple field extraction attempts
  // Falls back to token-based user ID if standard fields fail
  const fallbackId = `user-${Buffer.from(token).toString('base64').slice(0, 8)}`;
  return fallbackId;
}
```

### 2. Temporary Session Migration Logic
Added logic to handle existing anonymous sessions:

```javascript
// Migrate anonymous sessions to identified users
if (userId.startsWith('user-') && session.userId === 'anonymous') {
  console.log(`🔄 Migrating anonymous session ${sessionId} to user ${userId}`);
  session.userId = userId;
}
```

### 3. Debug Endpoints Added
- `/debug/user-info` - Shows JWT token parsing details
- `/debug/sessions` - Shows all sessions grouped by user
- `/debug/reset-sessions` - Resets sessions for current user
- `/debug/migrate-sessions` - Migrates anonymous sessions to current user

## Quick Fix for Users

### Option 1: Clear Browser Storage (Recommended)
1. Open browser dev tools (F12)
2. Go to Application > Local Storage
3. Delete the 'devops-user' entry
4. Refresh the page and login again

### Option 2: Use Debug Endpoints
```bash
# Reset your sessions
curl -X POST http://localhost:3001/debug/reset-sessions \
  -H "Authorization: Bearer YOUR_TOKEN"

# Migrate anonymous sessions
curl -X POST http://localhost:3001/debug/migrate-sessions \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Option 3: Run Fix Script
```powershell
# Run the automated fix script
.\scripts\fix-user-isolation-issue.ps1
```

## For Developers - Debugging Steps

### 1. Check JWT Token Parsing
```javascript
// In browser console after login:
const user = JSON.parse(localStorage.getItem('devops-user'));
fetch('/debug/user-info', {
  headers: { Authorization: 'Bearer ' + user.accessToken }
}).then(r => r.json()).then(console.log);
```

### 2. Check Server Logs
Look for these log messages:
- `🔍 JWT Token payload keys: [...]`
- `✅ Extracted user ID from token: [user-id]`
- `🔄 Using fallback user ID: [fallback-id]`

### 3. Check Session Ownership
```javascript
// Check session ownership in server logs:
// "🔍 Session ownership check: session.userId="X", requestUserId="Y""
```

## Permanent Fix (To Be Implemented)

### 1. Proper Cognito JWT Verification
```javascript
// TODO: Implement proper JWT signature verification
const jwt = require('jsonwebtoken');
const jwksClient = require('jwks-rsa');

// Verify JWT signature against Cognito public keys
const client = jwksClient({
  jwksUri: `https://cognito-idp.${region}.amazonaws.com/${userPoolId}/.well-known/jwks.json`
});
```

### 2. Standardized User ID Extraction
```javascript
// TODO: Standardize on specific Cognito token field
// Cognito Access Token: use 'username' field
// Cognito ID Token: use 'cognito:username' or 'email' field
```

### 3. Session Migration Strategy
```javascript
// TODO: Implement proper session migration for existing users
// - Identify sessions by browser fingerprint
// - Migrate based on email/username matching
// - Provide user confirmation for session ownership
```

## Testing

### Automated Tests
```bash
# Test JWT parsing
node tests/test-jwt-debug.js

# Test user isolation
node tests/test-user-isolation.js

# Test new session functionality
node tests/test-new-session-fix.js
```

### Manual Testing
1. Login with different users
2. Create chat sessions
3. Verify each user only sees their own sessions
4. Test cross-user access (should be blocked)
5. Verify legitimate access works

## Monitoring

### Server Logs to Watch
- JWT token parsing success/failure
- User ID extraction results
- Session ownership validation
- 403 Forbidden responses

### Metrics to Track
- Authentication success rate
- Session creation rate per user
- 403 error rate
- Token parsing failure rate

## Rollback Plan

If issues persist:

1. **Disable User Isolation Temporarily**
```javascript
// Comment out ownership validation in getOrCreateSession()
// if (session.userId !== userId) { ... }
```

2. **Revert to Anonymous Sessions**
```javascript
// Force all sessions to be anonymous
function getUserIdFromToken(authHeader) {
  return 'anonymous';
}
```

3. **Clear All Sessions**
```javascript
// Reset all sessions
sessions.clear();
```

## Status

- ✅ Enhanced JWT token parsing with debugging
- ✅ Fallback user ID generation
- ✅ Session migration logic for anonymous sessions
- ✅ Debug endpoints for troubleshooting
- ✅ Fix script for users
- 🔄 Monitoring server logs for JWT parsing issues
- ⏳ Waiting for user feedback on fix effectiveness

## Next Steps

1. Monitor server logs for JWT parsing patterns
2. Identify the correct Cognito token field to use
3. Implement proper JWT signature verification
4. Remove fallback mechanisms once stable
5. Add proper session migration for existing users