# Project Organization Script
# Moves files into proper directory structure

Write-Host "🗂️ Organizing DevOps KnowledgeOps Agent Project..." -ForegroundColor Cyan

# Create organized directory structure
$directories = @(
    "docs/setup",
    "docs/guides", 
    "docs/analysis",
    "docs/fixes",
    "tests/agentcore",
    "tests/memory",
    "tests/auth",
    "tests/integration",
    "tests/utilities"
)

foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "✅ Created directory: $dir" -ForegroundColor Green
    }
}

# Move documentation files
$docMoves = @{
    # Setup Documentation
    "BEDROCK_CONFIGURATION.md" = "docs/setup/"
    "AGENTCORE_IMPLEMENTATION_GUIDE.md" = "docs/setup/"
    "AGENTCORE_SETUP_COMPLETE.md" = "docs/setup/"
    "COGNITO_AUTHENTICATION_SETUP.md" = "docs/setup/"
    "COGNITO_INTEGRATION_GUIDE.md" = "docs/setup/"
    
    # Analysis Documentation
    "AGENTCORE_ANALYSIS.md" = "docs/analysis/"
    "AGENTCORE_STATUS_REPORT.md" = "docs/analysis/"
    "AGENTCORE_GATEWAY_ANALYSIS.md" = "docs/analysis/"
    "MEMORY_CROSS_SESSION_ANALYSIS.md" = "docs/analysis/"
    "SESSION_DURATION_ANALYSIS.md" = "docs/analysis/"
    
    # User Guides
    "AGENTCORE_GATEWAY_EXPLAINED.md" = "docs/guides/"
    "AWS_BEDROCK_MEMORY_GUIDE.md" = "docs/guides/"
    "SEMANTIC_MEMORY_UPGRADE_GUIDE.md" = "docs/guides/"
    "MEMORY_PERSISTENCE_SOLUTIONS.md" = "docs/guides/"
    
    # Fix Documentation
    "LOGIN_SESSION_FIX_SUMMARY.md" = "docs/fixes/"
    "LAMBDA_MEMORY_MANAGER_FIXES.md" = "docs/fixes/"
    "CHAT_HISTORY_FIX_SUMMARY.md" = "docs/fixes/"
    "FRONTEND_CHAT_HISTORY_FIXES.md" = "docs/fixes/"
    "API_FIXES_SUMMARY.md" = "docs/fixes/"
    "SESSION_ISOLATION_SECURITY_FIX.md" = "docs/fixes/"
    "CHAT_HISTORY_DEBUG_FIX.md" = "docs/fixes/"
    "EMPTY_SESSIONS_FIX_SUMMARY.md" = "docs/fixes/"
    "SIMPLIFIED_CHAT_HISTORY_SUMMARY.md" = "docs/fixes/"
    "COGNITO_MIGRATION_SUMMARY.md" = "docs/fixes/"
    "PATH_UPDATES_SUMMARY.md" = "docs/fixes/"
    "CHAT_HISTORY_STATUS_REPORT.md" = "docs/fixes/"
    "BEDROCK_STATUS_REPORT.md" = "docs/fixes/"
}

# Move test files
$testMoves = @{
    # AgentCore Tests
    "test-agentcore-gateway.js" = "tests/agentcore/"
    "test-agentcore-memory.js" = "tests/agentcore/"
    "test-agentcore-setup.js" = "tests/agentcore/"
    
    # Memory Tests
    "test-memory-training.js" = "tests/memory/"
    "test-cross-session-memory.js" = "tests/memory/"
    "test-semantic-memory.js" = "tests/memory/"
    "test-user-memory-persistence.js" = "tests/memory/"
    
    # Authentication Tests
    "test-cognito-integration.js" = "tests/auth/"
    "test-cognito-session-isolation.js" = "tests/auth/"
    "test-frontend-auth-status.js" = "tests/auth/"
    "test-login-session-fix.js" = "tests/auth/"
    
    # Integration Tests
    "test-session-isolation.js" = "tests/integration/"
    "test-session-isolation-current.js" = "tests/integration/"
    "test-session-isolation-fixed.js" = "tests/integration/"
    "test-chat-history.js" = "tests/integration/"
    "test-frontend-fixes.js" = "tests/integration/"
    "test-api-service.js" = "tests/integration/"
    "test-debug-component.js" = "tests/integration/"
    "test-session-fix.js" = "tests/integration/"
    
    # Utility Tests
    "test-bedrock-configuration.js" = "tests/utilities/"
    "test-bedrock-simple.js" = "tests/utilities/"
    "test-auto-cleanup.js" = "tests/utilities/"
    "test-delete-sessions.js" = "tests/utilities/"
    "test-browser-simulation.js" = "tests/utilities/"
    "debug-token-generation.js" = "tests/utilities/"
    "verify-real-bedrock.js" = "tests/utilities/"
    "create-test-user.js" = "tests/utilities/"
    "check-bedrock-memory-config.js" = "tests/utilities/"
}

# Utility files to move
$utilityMoves = @{
    "implement-user-memory-system.js" = "tests/utilities/"
    "update-to-semantic-memory.js" = "tests/utilities/"
    "user-context-solution.js" = "tests/utilities/"
}

Write-Host "`n📁 Moving documentation files..." -ForegroundColor Yellow

foreach ($file in $docMoves.Keys) {
    if (Test-Path $file) {
        $destination = $docMoves[$file]
        Move-Item $file $destination -Force
        Write-Host "   ✅ Moved $file → $destination" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️ File not found: $file" -ForegroundColor Yellow
    }
}

Write-Host "`n🧪 Moving test files..." -ForegroundColor Yellow

foreach ($file in $testMoves.Keys) {
    if (Test-Path $file) {
        $destination = $testMoves[$file]
        Move-Item $file $destination -Force
        Write-Host "   ✅ Moved $file → $destination" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️ File not found: $file" -ForegroundColor Yellow
    }
}

Write-Host "`n🔧 Moving utility files..." -ForegroundColor Yellow

foreach ($file in $utilityMoves.Keys) {
    if (Test-Path $file) {
        $destination = $utilityMoves[$file]
        Move-Item $file $destination -Force
        Write-Host "   ✅ Moved $file → $destination" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️ File not found: $file" -ForegroundColor Yellow
    }
}

# Create organized README files for each directory
Write-Host "`n📝 Creating directory README files..." -ForegroundColor Yellow

# Main project README update
$mainReadme = @"
# DevOps KnowledgeOps Agent

AI-powered DevOps assistant built with Amazon Bedrock AgentCore.

## 🚀 Quick Start

1. **Setup**: Run ``scripts/setup-simple.ps1``
2. **Start Backend**: Run ``start-backend.ps1``
3. **Start Frontend**: ``cd frontend && npm start``
4. **Test**: Run ``tests/agentcore/test-agentcore-setup.js``

## 📁 Project Structure

- **``frontend/``** - React.js web application
- **``backend/``** - Express.js API server with AgentCore Gateway
- **``lambda/``** - AWS Lambda functions for serverless deployment
- **``infrastructure/``** - AWS CDK infrastructure code
- **``scripts/``** - Setup and deployment scripts
- **``docs/``** - Documentation organized by category
- **``tests/``** - Test files organized by component
- **``knowledge-base/``** - DevOps knowledge content

## 🎯 Key Features

- ✅ **AgentCore Gateway**: 99.9% performance improvement with caching
- ✅ **AgentCore Memory**: 30-day conversation memory
- ✅ **Cognito Authentication**: Secure user management
- ✅ **Session Management**: Multi-user session isolation
- ✅ **Real-time Chat**: WebSocket-like experience
- ✅ **Knowledge Base**: DevOps expertise and troubleshooting

## 📚 Documentation

- **Setup Guides**: ``docs/setup/``
- **User Guides**: ``docs/guides/``
- **Technical Analysis**: ``docs/analysis/``
- **Fix Documentation**: ``docs/fixes/``

## 🧪 Testing

- **AgentCore Tests**: ``tests/agentcore/``
- **Memory Tests**: ``tests/memory/``
- **Auth Tests**: ``tests/auth/``
- **Integration Tests**: ``tests/integration/``

See individual README files in each directory for detailed information.
"@

$mainReadme | Out-File -FilePath "README.md" -Encoding UTF8 -Force

# Documentation directory READMEs
$docsSetupReadme = @"
# Setup Documentation

This directory contains setup and configuration guides.

## 📋 Files

- **BEDROCK_CONFIGURATION.md** - AWS Bedrock setup guide
- **AGENTCORE_IMPLEMENTATION_GUIDE.md** - AgentCore implementation
- **AGENTCORE_SETUP_COMPLETE.md** - Setup completion checklist
- **COGNITO_AUTHENTICATION_SETUP.md** - Cognito auth setup
- **COGNITO_INTEGRATION_GUIDE.md** - Cognito integration guide

## 🚀 Quick Setup

1. Follow BEDROCK_CONFIGURATION.md
2. Run setup scripts from ``../scripts/``
3. Verify with AGENTCORE_SETUP_COMPLETE.md
"@

$docsSetupReadme | Out-File -FilePath "docs/setup/README.md" -Encoding UTF8 -Force

$docsGuidesReadme = @"
# User Guides

This directory contains user-facing guides and explanations.

## 📋 Files

- **AGENTCORE_GATEWAY_EXPLAINED.md** - How AgentCore Gateway works
- **AWS_BEDROCK_MEMORY_GUIDE.md** - Memory configuration guide
- **SEMANTIC_MEMORY_UPGRADE_GUIDE.md** - Upgrading to semantic memory
- **MEMORY_PERSISTENCE_SOLUTIONS.md** - Cross-session memory solutions

## 🎯 Most Important

1. **AGENTCORE_GATEWAY_EXPLAINED.md** - Understand the 99.9% performance improvement
2. **MEMORY_PERSISTENCE_SOLUTIONS.md** - Enable cross-session memory
"@

$docsGuidesReadme | Out-File -FilePath "docs/guides/README.md" -Encoding UTF8 -Force

$testsReadme = @"
# Test Suite

Organized test files for different components.

## 📁 Directory Structure

- **``agentcore/``** - AgentCore Gateway and Memory tests
- **``memory/``** - Memory persistence and cross-session tests
- **``auth/``** - Authentication and Cognito tests
- **``integration/``** - Full system integration tests
- **``utilities/``** - Utility functions and configuration tests

## 🧪 Key Tests

- **``agentcore/test-agentcore-setup.js``** - Complete system diagnostic
- **``memory/test-memory-training.js``** - Memory functionality test
- **``auth/test-cognito-integration.js``** - Authentication test

## 🚀 Run All Tests

``node tests/agentcore/test-agentcore-setup.js``
"@

$testsReadme | Out-File -FilePath "tests/README.md" -Encoding UTF8 -Force

Write-Host "✅ Created README files for organized directories" -ForegroundColor Green

Write-Host "`n🎉 Project organization complete!" -ForegroundColor Green
Write-Host "`n📁 New structure:" -ForegroundColor Cyan
Write-Host "   docs/" -ForegroundColor White
Write-Host "   ├── setup/     (Setup guides)" -ForegroundColor Gray
Write-Host "   ├── guides/    (User guides)" -ForegroundColor Gray
Write-Host "   ├── analysis/  (Technical analysis)" -ForegroundColor Gray
Write-Host "   └── fixes/     (Fix documentation)" -ForegroundColor Gray
Write-Host "   tests/" -ForegroundColor White
Write-Host "   ├── agentcore/ (AgentCore tests)" -ForegroundColor Gray
Write-Host "   ├── memory/    (Memory tests)" -ForegroundColor Gray
Write-Host "   ├── auth/      (Auth tests)" -ForegroundColor Gray
Write-Host "   ├── integration/ (Integration tests)" -ForegroundColor Gray
Write-Host "   └── utilities/ (Utility tests)" -ForegroundColor Gray

Write-Host "`n🎯 Next steps:" -ForegroundColor Yellow
Write-Host "   1. Review the organized structure" -ForegroundColor White
Write-Host "   2. Update any scripts that reference moved files" -ForegroundColor White
Write-Host "   3. Use the new README files for navigation" -ForegroundColor White