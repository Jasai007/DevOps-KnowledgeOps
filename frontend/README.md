# DevOps KnowledgeOps Frontend

A modern React-based chat interface for the DevOps KnowledgeOps Agent, providing an intuitive way to interact with AI-powered DevOps expertise.

## Overview

This frontend application serves as the user interface for the DevOps KnowledgeOps Agent. It features a clean chat interface built with Material-UI, supporting real-time conversations with an AI-powered DevOps assistant backed by Amazon Bedrock AgentCore.

## Features

- **Clean Chat Interface**: Modern, responsive chat UI with message bubbles and typing indicators
- **Authentication Integration**: AWS Cognito authentication for secure user sessions
- **Rich Message Formatting**: Support for markdown, code blocks, syntax highlighting, and file path highlighting
- **Responsive Design**: Mobile-friendly interface that works across all devices
- **Real-time Communication**: Direct API integration for instant responses

## Technology Stack

- **React 18**: Modern React with hooks and functional components
- **TypeScript**: Type-safe development
- **Material-UI (MUI)**: Component library for consistent, accessible UI
- **Axios**: HTTP client for API communication
- **React Syntax Highlighter**: Code syntax highlighting in chat messages

## Project Structure

```
frontend/
├── public/                 # Static assets
│   ├── index.html         # Main HTML template
│   └── manifest.json      # PWA manifest
├── src/
│   ├── components/        # React components
│   │   ├── Auth/         # Authentication components
│   │   ├── Chat/         # Chat interface components
│   │   │   ├── ChatContainer.tsx    # Main chat container
│   │   │   ├── ChatInput.tsx        # Message input component
│   │   │   ├── MessageBubble.tsx    # Individual message display
│   │   │   └── SuggestionChips.tsx  # Quick suggestion buttons
│   │   ├── Header/        # App header component
│   │   └── Layout/        # Layout wrapper components
│   ├── contexts/          # React contexts
│   │   └── AuthContext.tsx # Authentication state management
│   ├── services/          # API service layer
│   │   └── api.ts         # API client configuration
│   ├── App.tsx            # Main application component
│   ├── App.css            # Global styles
│   └── index.tsx          # Application entry point
├── package.json           # Dependencies and scripts
├── tsconfig.json          # TypeScript configuration
└── README.md             # This file
```

## Local Development

### Prerequisites

- Node.js 18+ and npm
- Backend server running (see backend README)

### Setup

1. **Install dependencies**:
   ```bash
   cd frontend
   npm install
   ```

2. **Start development server**:
   ```bash
   npm start
   ```

   The application will be available at `http://localhost:3000`

3. **Build for production**:
   ```bash
   npm run build
   ```

   This creates an optimized production build in the `build/` directory.

### Available Scripts

- `npm start`: Start development server with hot reload
- `npm run build`: Create production build
- `npm test`: Run test suite
- `npm run eject`: Eject from Create React App (not recommended)

## Environment Configuration

The frontend expects the backend API to be running. Update the API base URL in `src/services/api.ts` if needed:

```typescript
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:3001/api';
```

## Key Components

### ChatContainer
Main chat interface managing message state, authentication, and API communication.

### MessageBubble
Displays individual messages with support for:
- Markdown formatting (# ## ### headings)
- Code blocks with syntax highlighting
- Inline code snippets
- File extension highlighting (.tsx, .js, etc.)
- File path highlighting (folder/file structures)

### AuthContext
Manages user authentication state using AWS Cognito.

### API Service
Handles all backend communication with proper error handling and authentication headers.

## Deployment

### Production Build

1. **Build the application**:
   ```bash
   npm run build
   ```

2. **Serve static files**:
   The `build/` directory contains static files that can be served by any web server (nginx, Apache, etc.) or deployed to cloud hosting like AWS S3 + CloudFront.

### Environment Variables

For production deployment, set:
- `REACT_APP_API_URL`: Backend API URL
- `REACT_APP_COGNITO_USER_POOL_ID`: Cognito User Pool ID
- `REACT_APP_COGNITO_CLIENT_ID`: Cognito Client ID

## Browser Support

- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

## Contributing

1. Follow the existing code style and TypeScript conventions
2. Add proper type definitions for new components
3. Test components across different screen sizes
4. Ensure accessibility compliance with Material-UI standards

## Troubleshooting

### Common Issues

- **API Connection Errors**: Ensure backend server is running and CORS is configured
- **Authentication Issues**: Verify Cognito configuration and user pool settings
- **Build Errors**: Clear node_modules and reinstall dependencies

### Development Tips

- Use React DevTools for debugging component state
- Check browser console for API errors
- Test on multiple screen sizes using browser dev tools
