# 👥 Creating New Users Guide

## 🎯 Multiple Ways to Create New Users

### Method 1: Using PowerShell Script (Recommended)

I've created a simple script to create new users:

```powershell
# Create a new user
.\create-user.ps1 -Email "john.doe@company.com" -Password "SecurePass123!"
```

**Example:**
```powershell
.\create-user.ps1 -Email "sarah@mycompany.com" -Password "MyPassword123!"
```

### Method 2: Using AWS CLI Directly

```powershell
# Step 1: Create the user
aws cognito-idp admin-create-user `
  --user-pool-id us-east-1_QVdUR725D `
  --username "newuser@example.com" `
  --user-attributes Name=email,Value="newuser@example.com" Name=email_verified,Value=true `
  --temporary-password "TempPass123!" `
  --message-action SUPPRESS `
  --region us-east-1

# Step 2: Set permanent password
aws cognito-idp admin-set-user-password `
  --user-pool-id us-east-1_QVdUR725D `
  --username "newuser@example.com" `
  --password "FinalPassword123!" `
  --permanent `
  --region us-east-1
```

### Method 3: Using the Frontend Signup Form

I've added a signup form to your application:

1. **Start the application**:
   ```powershell
   .\start-with-cognito.ps1
   cd frontend && npm start
   ```

2. **Access signup**:
   - Go to the login page
   - Click "Create Account" link
   - Fill in email and password
   - Submit the form

3. **Automatic login**: After successful signup, users are automatically logged in

## 🔐 Password Requirements

Your Cognito User Pool has these password requirements:
- **Minimum length**: 8 characters
- **No complexity requirements** (for demo purposes)

For production, you might want stricter requirements:
```powershell
# Update password policy (optional)
aws cognito-idp update-user-pool `
  --user-pool-id us-east-1_QVdUR725D `
  --policies "PasswordPolicy={MinimumLength=12,RequireUppercase=true,RequireLowercase=true,RequireNumbers=true,RequireSymbols=true}" `
  --region us-east-1
```

## 🧪 Testing New Users

### Test with PowerShell Script
```powershell
# Create test user
.\create-user.ps1 -Email "test@example.com" -Password "TestPass123!"

# Test authentication
node test-cognito-auth.js
```

### Test with Frontend
1. Create account via signup form
2. Verify login works
3. Check that chat sessions are user-specific

## 📋 User Management Commands

### List All Users
```powershell
aws cognito-idp list-users --user-pool-id us-east-1_QVdUR725D --region us-east-1
```

### Delete a User
```powershell
aws cognito-idp admin-delete-user `
  --user-pool-id us-east-1_QVdUR725D `
  --username "user@example.com" `
  --region us-east-1
```

### Reset User Password
```powershell
aws cognito-idp admin-set-user-password `
  --user-pool-id us-east-1_QVdUR725D `
  --username "user@example.com" `
  --password "NewPassword123!" `
  --permanent `
  --region us-east-1
```

### Disable/Enable User
```powershell
# Disable user
aws cognito-idp admin-disable-user `
  --user-pool-id us-east-1_QVdUR725D `
  --username "user@example.com" `
  --region us-east-1

# Enable user
aws cognito-idp admin-enable-user `
  --user-pool-id us-east-1_QVdUR725D `
  --username "user@example.com" `
  --region us-east-1
```

## 🚀 Quick Examples

### Create Multiple Users
```powershell
# Create several users at once
$users = @(
    @{email="alice@company.com"; password="Alice123!"},
    @{email="bob@company.com"; password="Bob123!"},
    @{email="charlie@company.com"; password="Charlie123!"}
)

foreach ($user in $users) {
    .\create-user.ps1 -Email $user.email -Password $user.password
    Write-Host "Created: $($user.email)" -ForegroundColor Green
}
```

### Bulk User Creation from CSV
```powershell
# Create users.csv with columns: email,password
# Then run:
Import-Csv "users.csv" | ForEach-Object {
    .\create-user.ps1 -Email $_.email -Password $_.password
}
```

## 🔧 API Integration

Your API server now supports user registration:

```javascript
// POST /auth
{
  "action": "signup",
  "username": "newuser@example.com",
  "email": "newuser@example.com", 
  "password": "SecurePass123!"
}
```

**Response:**
```javascript
{
  "success": true,
  "message": "User created successfully"
}
```

## 🎉 Summary

You now have **4 ways** to create new users:

1. ✅ **PowerShell Script** - `.\create-user.ps1`
2. ✅ **AWS CLI** - Direct Cognito commands
3. ✅ **Frontend Signup** - User-friendly web form
4. ✅ **API Endpoint** - Programmatic creation

All new users will have:
- ✅ **Email-based authentication**
- ✅ **Secure password storage**
- ✅ **Isolated chat sessions**
- ✅ **JWT token authentication**
- ✅ **Session persistence**

Your application is ready for real users! 🚀