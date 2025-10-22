# Project Organization

This document describes the organized structure of the DevOps KnowledgeOps Agent project.

## Directory Structure

```
├── .kiro/                          # Kiro IDE configuration and specs
│   └── specs/
│       └── devops-knowledgeops-agent/
├── backend/                        # Express.js backend server
├── frontend/                       # React frontend application
├── lambda/                         # AWS Lambda functions
│   ├── actions/                    # Lambda action handlers
│   ├── bedrock/                    # Bedrock integration
│   ├── chat-processor/             # Chat processing logic
│   ├── memory/                     # Memory management
│   ├── session/                    # Session handling
│   ├── types/                      # TypeScript type definitions
│   └── utils/                      # Utility functions
├── infrastructure/                 # AWS CDK infrastructure code
├── knowledge-base/                 # Knowledge base content
│   ├── aws/                        # AWS-specific documentation
│   └── infrastructure/             # Infrastructure guides
├── scripts/                        # Utility scripts
│   ├── setup/                      # Setup and installation scripts
│   ├── deployment/                 # Deployment scripts
│   └── maintenance/                # Maintenance and utility scripts
├── tests/                          # Test files organized by category
│   ├── auth/                       # Authentication tests
│   ├── bedrock/                    # Bedrock integration tests
│   ├── frontend/                   # Frontend component tests
│   ├── integration/                # Integration tests
│   ├── memory/                     # Memory system tests
│   └── unit/                       # Unit tests
├── docs/                           # Documentation
│   ├── analysis/                   # Technical analysis documents
│   ├── guides/                     # Setup and implementation guides
│   └── summaries/                  # Fix summaries and reports
├── config/                         # Configuration files
└── tools/                          # Development tools
```

## File Categories

### Documentation (`docs/`)

#### Guides (`docs/guides/`)
- Setup and implementation guides
- AWS service configuration guides
- Memory system documentation
- Authentication setup guides

#### Analysis (`docs/analysis/`)
- Technical analysis documents
- Status reports
- Component explanations

#### Summaries (`docs/summaries/`)
- Fix summaries
- Implementation reports
- Change logs

### Tests (`tests/`)

#### Authentication (`tests/auth/`)
- Cognito integration tests
- Login/logout functionality tests
- Token generation and validation tests

#### Bedrock (`tests/bedrock/`)
- AgentCore integration tests
- Bedrock configuration tests
- Vector store tests

#### Frontend (`tests/frontend/`)
- React component tests
- UI interaction tests
- Debug component tests

#### Integration (`tests/integration/`)
- End-to-end workflow tests
- Session isolation tests
- API integration tests

#### Memory (`tests/memory/`)
- Memory persistence tests
- Cross-session memory tests
- Semantic memory tests

### Scripts (`scripts/`)

#### Setup (`scripts/setup/`)
- Initial project setup scripts
- AWS service configuration scripts
- Migration scripts

#### Deployment (`scripts/deployment/`)
- Deployment automation scripts
- Environment setup scripts

#### Maintenance (`scripts/maintenance/`)
- Server restart scripts
- Fix application scripts
- Utility and helper scripts

## Key Files

### Root Level
- `README.md` - Main project documentation
- `package.json` - Node.js dependencies and scripts
- `tsconfig.json` - TypeScript configuration
- `jest.config.js` - Jest testing configuration

### Configuration
- `devops-config.env` - Environment configuration
- Backend and Lambda package.json files for service-specific dependencies

## Usage Guidelines

1. **Tests**: Run tests from their respective directories based on what you're testing
2. **Scripts**: Use setup scripts for initial configuration, maintenance scripts for ongoing operations
3. **Documentation**: Check guides for setup instructions, analysis for technical details, summaries for recent changes
4. **Development**: Main application code is in `backend/`, `frontend/`, and `lambda/` directories

## Benefits of This Organization

- **Clear Separation**: Tests, documentation, and scripts are properly categorized
- **Easy Navigation**: Related files are grouped together
- **Maintainability**: Easier to find and update specific components
- **Scalability**: Structure supports adding new features and tests
- **Development Workflow**: Supports both development and operational needs