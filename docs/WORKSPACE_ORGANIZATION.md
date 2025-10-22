# DevOps KnowledgeOps Agent - Workspace Organization

## 📁 Directory Structure

```
DevOps-KnowledgeOps/
├── 📂 backend/                    # Backend server and API
│   ├── agentcore-gateway.js       # AgentCore Gateway implementation
│   ├── agentcore-memory.js        # AgentCore Memory management
│   ├── server.js                  # Main server with full features
│   ├── server-fallback.js         # Fallback server for testing
│   ├── package.json               # Backend dependencies
│   └── config/                    # Configuration files
│       ├── cognito-config.env     # Cognito settings
│       ├── kb-config.json         # Knowledge base config
│       └── kb-config-s3.json      # S3 knowledge base config
│
├── 📂 frontend/                   # React frontend application
│   ├── src/                      # Source code
│   ├── public/                   # Static assets
│   └── package.json              # Frontend dependencies
│
├── 📂 scripts/                   # Startup and utility scripts
│   ├── start-smart.ps1           # Smart startup (auto-detects mode)
│   ├── start-with-cognito.ps1    # Start with Cognito auth
│   ├── start-devops-ai.ps1       # Basic startup script
│   └── setup/                    # Setup scripts
│       ├── setup-cognito.ps1     # Cognito setup
│       └── setup-agentcore.ps1   # AgentCore setup
│
├── 📂 tests/                     # Test files and utilities
│   ├── test-agentcore.js         # AgentCore functionality tests
│   ├── test-bedrock-agent.js     # Bedrock Agent connectivity test
│   ├── test-server-connection.js # Server endpoint tests
│   └── test-conversation-memory.js # Memory functionality test
│
├── 📂 lambda/                    # AWS Lambda functions
│   ├── auth/                     # Authentication functions
│   ├── bedrock/                  # Bedrock integrations
│   └── memory/                   # Memory management
│
├── 📂 infrastructure/            # AWS CDK infrastructure code
│   ├── app.ts                    # CDK app entry point
│   └── devops-knowledgeops-stack.ts # Main stack
│
├── 📂 knowledge-base/            # DevOps documentation
│   ├── aws/                      # AWS-specific docs
│   ├── kubernetes/               # Kubernetes guides
│   ├── docker/                   # Docker best practices
│   └── cicd/                     # CI/CD documentation
│
├── 📂 docs/                      # Project documentation
│   ├── README-SETUP.md           # Setup instructions
│   ├── WORKSPACE_ORGANIZATION.md # This file
│   └── summaries/                # Project summaries
│
├── 📂 tools/                     # Development tools
│   └── start-with-cognito.ps1    # Cognito-specific tools
│
├── 📂 .kiro/                     # Kiro IDE configuration
│   ├── specs/                    # Feature specifications
│   └── settings/                 # IDE settings
│
└── 📄 Root Files
    ├── README.md                  # Main project README
    ├── package.json               # Workspace configuration
    └── tsconfig.json              # TypeScript configuration
```

## 🚀 Quick Start Commands

### **Recommended: Smart Startup**
```powershell
# From project root
.\scripts\start-smart.ps1
```
*Automatically detects configuration and chooses the best mode*

### **Manual Testing**
```powershell
# Test Bedrock Agent
node tests/test-bedrock-agent.js

# Test server connection
node tests/test-server-connection.js

# Test AgentCore features
node tests/test-agentcore.js
```

### **Development Modes**

**Full Mode (with Bedrock Agent):**
```powershell
cd backend
node server.js
```

**Fallback Mode (for testing UI):**
```powershell
cd backend
node server-fallback.js
```

## 📋 File Organization Rules

### **Scripts Directory (`scripts/`)**
- All PowerShell startup scripts
- Setup and configuration scripts
- Deployment automation

### **Tests Directory (`tests/`)**
- All test files (`test-*.js`)
- Validation and diagnostic scripts
- Connection and functionality tests

### **Backend Directory (`backend/`)**
- Server implementation files
- AgentCore components
- Configuration files in `config/` subdirectory

### **Docs Directory (`docs/`)**
- Project documentation
- Setup guides
- Architecture documentation

### **Tools Directory (`tools/`)**
- Development utilities
- Helper scripts
- Build tools

## 🎯 Benefits of This Organization

✅ **Clean Root Directory** - Only essential project files
✅ **Logical Grouping** - Related files are together
✅ **Easy Navigation** - Clear directory purposes
✅ **Scalable Structure** - Easy to add new components
✅ **IDE Friendly** - Better file discovery and management

## 🔧 Maintenance

When adding new files:
- **Scripts** → `scripts/` directory
- **Tests** → `tests/` directory  
- **Documentation** → `docs/` directory
- **Tools** → `tools/` directory
- **Backend code** → `backend/` directory
- **Frontend code** → `frontend/src/` directory

This keeps the workspace clean and organized for better development experience.