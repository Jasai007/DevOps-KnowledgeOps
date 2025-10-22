require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');
const crypto = require('crypto');
const AWS = require('aws-sdk');

// AgentCore Components
const { AgentCoreGateway } = require('./agentcore-gateway');

/** @type {import('express').Application} */
const app = express();
const PORT = process.env.PORT || 3001;

// CORS Configuration for production
const corsOptions = {
  origin: function (origin, callback) {
    // Allow requests with no origin (mobile apps, curl, etc.)
    if (!origin) return callback(null, true);

    const allowedOrigins = [
      'http://localhost:3000', // Development
      'http://127.0.0.1:3000', // Development
      'https://prod.d3jls0eav9ubbd.amplifyapp.com', // Production Amplify URL
      process.env.FRONTEND_URL, // Production frontend URL from env
      /^https:\/\/[a-zA-Z0-9-]+\.cloudfront\.net$/, // CloudFront distributions
      /^https:\/\/[a-zA-Z0-9-]+\.s3-website-[a-zA-Z0-9-]+\.amazonaws\.com$/, // S3 static hosting
      /^https:\/\/[a-zA-Z0-9-]+\.amplifyapp\.com$/ // Amplify hosting
    ].filter(Boolean); // Remove undefined values

    // Check if origin matches any allowed pattern
    const isAllowed = allowedOrigins.some(allowedOrigin => {
      if (typeof allowedOrigin === 'string') {
        return allowedOrigin === origin;
      } else if (allowedOrigin instanceof RegExp) {
        return allowedOrigin.test(origin);
      }
      return false;
    });

    if (isAllowed) {
      callback(null, true);
    } else {
      console.log(`CORS blocked origin: ${origin}`);
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  exposedHeaders: ['Access-Control-Allow-Origin']
};

app.use(cors(corsOptions));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Add explicit CORS headers for better compatibility
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', req.headers.origin || '*');
  res.header('Access-Control-Allow-Credentials', 'true');
  res.header('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE,OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type,Authorization,X-Requested-With');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }
  next();
});

// AWS Configuration
const AWS_REGION = process.env.AWS_REGION || 'us-east-1';
const BEDROCK_AGENT_ID = process.env.BEDROCK_AGENT_ID || 'MNJESZYALW';
const BEDROCK_AGENT_ALIAS_ID = process.env.BEDROCK_AGENT_ALIAS_ID || 'TSTALIASID';

// Cognito Configuration (optional - fallback to mock auth if not configured)
const USER_POOL_ID = process.env.USER_POOL_ID;
const USER_POOL_CLIENT_ID = process.env.USER_POOL_CLIENT_ID;
const USER_POOL_CLIENT_SECRET = process.env.USER_POOL_CLIENT_SECRET;

// Helper function to calculate SECRET_HASH for Cognito
function calculateSecretHash(username, clientId, clientSecret) {
  const message = username + clientId;
  const hmac = crypto.createHmac('sha256', clientSecret);
  hmac.update(message);
  return hmac.digest('base64');
}

// Initialize Cognito client if configured
let cognitoClient = null;
if (USER_POOL_ID && USER_POOL_CLIENT_ID && USER_POOL_CLIENT_SECRET) {
  AWS.config.update({ region: AWS_REGION });
  cognitoClient = new AWS.CognitoIdentityServiceProvider();
  console.log('🔐 Cognito authentication enabled');
} else {
  console.log('🔐 Using mock authentication (Cognito not configured)');
}

// In-memory session store for simplicity
const userSessions = new Map();
const userMemory = new Map();

// Logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Initialize AgentCore Gateway with memory enabled
const agentCoreGateway = new AgentCoreGateway({
  region: AWS_REGION,
  primaryAgentId: BEDROCK_AGENT_ID,
  primaryAliasId: BEDROCK_AGENT_ALIAS_ID,
  enableCaching: false, // Disable caching to rely on AgentCore native memory
  enableMetrics: true,
  maxRetries: 2,
  timeoutMs: 30000,
  enableMemory: true // Enable AgentCore native memory
});

// Helper function to get or create user session
function getUserFromRequest(req) {
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.substring(7);
    const session = userSessions.get(token);
    if (session && new Date(session.expiresAt) > new Date()) {
      return session.userId;
    }
  }
  return null;
}

// Helper function to create user memory context
function getUserMemory(userId) {
  if (!userMemory.has(userId)) {
    userMemory.set(userId, {
      conversations: [],
      preferences: {},
      skillLevel: 'intermediate',
      technologyStack: [],
      infrastructureContext: '',
      createdAt: new Date().toISOString()
    });
  }
  return userMemory.get(userId);
}

// Helper function to update user memory
function updateUserMemory(userId, message, response) {
  const memory = getUserMemory(userId);

  // Add conversation to memory
  memory.conversations.push({
    timestamp: new Date().toISOString(),
    userMessage: message,
    agentResponse: response,
    messageLength: message.length,
    responseLength: response.length
  });

  // Keep only last 10 conversations for context
  if (memory.conversations.length > 10) {
    memory.conversations = memory.conversations.slice(-10);
  }

  // Extract and update preferences/context from conversation
  const lowerMessage = message.toLowerCase();

  // Detect technology stack mentions
  const technologies = ['docker', 'kubernetes', 'terraform', 'jenkins', 'aws', 'azure', 'gcp', 'prometheus', 'grafana'];
  technologies.forEach(tech => {
    if (lowerMessage.includes(tech) && !memory.technologyStack.includes(tech)) {
      memory.technologyStack.push(tech);
    }
  });

  // Detect skill level indicators
  if (lowerMessage.includes('beginner') || lowerMessage.includes('new to')) {
    memory.skillLevel = 'beginner';
  } else if (lowerMessage.includes('advanced') || lowerMessage.includes('expert')) {
    memory.skillLevel = 'advanced';
  }

  userMemory.set(userId, memory);
}

// Authentication endpoint with Cognito support (fallback to demo mode)
app.post('/api/auth', async (req, res) => {
  try {
    const { action, username, password } = req.body;

    console.log('Auth request:', { action, username });

    if (action === 'signin') {
      if (!username || !password) {
        return res.status(400).json({
          success: false,
          error: 'Username and password are required'
        });
      }

      // Use Cognito if configured, otherwise fallback to demo mode
      if (cognitoClient && USER_POOL_ID && USER_POOL_CLIENT_ID) {
        try {
          console.log('🔐 Attempting Cognito authentication...');

          const secretHash = calculateSecretHash(username, USER_POOL_CLIENT_ID, USER_POOL_CLIENT_SECRET);

          const authParams = {
            AuthFlow: 'USER_PASSWORD_AUTH',
            ClientId: USER_POOL_CLIENT_ID,
            AuthParameters: {
              USERNAME: username,
              PASSWORD: password,
              SECRET_HASH: secretHash
            }
          };

          const authResult = await cognitoClient.adminInitiateAuth(authParams).promise();

          if (authResult.AuthenticationResult) {
            const { AccessToken, IdToken, RefreshToken } = authResult.AuthenticationResult;

            // Decode ID token to get user info
            const jwt = require('jsonwebtoken');
            const decodedIdToken = jwt.decode(IdToken);

            const userId = decodedIdToken.sub || username;
            const userEmail = decodedIdToken.email || username;

            // Initialize user memory if not exists
            getUserMemory(userId);

            console.log(`✅ Cognito authentication successful for user: ${userId}`);

            res.json({
              success: true,
              data: {
                success: true,
                accessToken: AccessToken,
                idToken: IdToken,
                refreshToken: RefreshToken,
                user: {
                  email: userEmail,
                  username: username,
                  userId: userId
                },
                message: 'Login successful'
              }
            });
          } else {
            throw new Error('No authentication result from Cognito');
          }
        } catch (cognitoError) {
          console.log('❌ Cognito authentication failed, falling back to demo mode:', cognitoError.message);

          // Fallback to demo mode
          const sessionId = uuidv4();
          const userId = username;

          const session = {
            sessionId,
            userId,
            username,
            createdAt: new Date().toISOString(),
            expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()
          };

          userSessions.set(sessionId, session);
          getUserMemory(userId);

          console.log(`✅ Demo authentication fallback for user: ${userId}`);

          res.json({
            success: true,
            data: {
              success: true,
              accessToken: sessionId,
              idToken: sessionId,
              refreshToken: sessionId,
              user: {
                email: username,
                username: username,
                userId: userId
              },
              message: 'Login successful (demo mode)'
            }
          });
        }
      } else {
        // Demo mode only
        const sessionId = uuidv4();
        const userId = username;

        const session = {
          sessionId,
          userId,
          username,
          createdAt: new Date().toISOString(),
          expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()
        };

        userSessions.set(sessionId, session);
        getUserMemory(userId);

        console.log(`✅ Demo authentication for user: ${userId}`);

        res.json({
          success: true,
          data: {
            success: true,
            accessToken: sessionId,
            idToken: sessionId,
            refreshToken: sessionId,
            user: {
              email: username,
              username: username,
              userId: userId
            },
            message: 'Login successful (demo mode)'
          }
        });
      }
    } else if (action === 'signup') {
      if (cognitoClient && USER_POOL_ID) {
        try {
          console.log('🔐 Attempting Cognito user registration...');

          // Create user in Cognito
          await cognitoClient.adminCreateUser({
            UserPoolId: USER_POOL_ID,
            Username: username,
            UserAttributes: [
              {
                Name: 'email',
                Value: username
              },
              {
                Name: 'email_verified',
                Value: 'true'
              }
            ],
            TemporaryPassword: password,
            MessageAction: 'SUPPRESS'
          }).promise();

          // Set permanent password
          await cognitoClient.adminSetUserPassword({
            UserPoolId: USER_POOL_ID,
            Username: username,
            Password: password,
            Permanent: true
          }).promise();

          console.log(`✅ Cognito user registration successful for: ${username}`);

          res.json({
            success: true,
            message: 'Signup successful'
          });
        } catch (cognitoError) {
          console.log('❌ Cognito registration failed:', cognitoError.message);

          // Fallback to demo mode
          res.json({
            success: true,
            message: 'Signup successful (demo mode)'
          });
        }
      } else {
        // Demo mode only
        res.json({
          success: true,
          message: 'Signup successful (demo mode)'
        });
      }
    } else {
      res.status(400).json({
        success: false,
        error: 'Invalid action'
      });
    }
  } catch (error) {
    console.error('Auth error:', error);
    res.status(500).json({
      success: false,
      error: 'Authentication failed: ' + error.message
    });
  }
});

// Health check endpoint
app.get('/api/health', async (req, res) => {
  try {
    const gatewayHealth = await agentCoreGateway.healthCheck();

    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      region: AWS_REGION,
      agentId: BEDROCK_AGENT_ID,
      agentAliasId: BEDROCK_AGENT_ALIAS_ID,
      authType: cognitoClient ? 'cognito' : 'session',
      cognitoAuth: !!cognitoClient,
      agentCore: {
        gateway: {
          status: gatewayHealth.status,
          cacheSize: gatewayHealth.details.cacheSize,
          activeRequests: gatewayHealth.details.activeRequests
        }
      },
      features: {
        agentCoreGateway: true,
        cognitoAuth: !!cognitoClient,
        sessionAuth: true,
        userMemory: true,
        individualSessions: true
      },
      stats: {
        activeSessions: userSessions.size,
        usersWithMemory: userMemory.size
      }
    });
  } catch (error) {
    res.status(500).json({
      status: 'unhealthy',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Session management endpoint
app.post('/api/session', async (req, res) => {
  try {
    const { action } = req.body;

    if (action === 'create' || !action) {
      const sessionId = uuidv4();

      res.json({
        success: true,
        sessionId: sessionId,
        createdAt: new Date().toISOString(),
        expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
        metadata: {
          agentId: BEDROCK_AGENT_ID,
          memoryEnabled: true
        }
      });
    } else {
      res.json({
        success: true,
        message: 'Session action processed'
      });
    }
  } catch (error) {
    console.error('Session error:', error);
    res.status(500).json({
      success: false,
      error: 'Session management failed: ' + error.message
    });
  }
});

// Chat endpoint with AgentCore and individual user memory
app.post('/api/chat', async (req, res) => {
  const startTime = Date.now();

  try {
    const { message, sessionId } = req.body;

    if (!message || !message.trim()) {
      return res.status(400).json({
        success: false,
        error: 'Message is required'
      });
    }

    console.log('Chat request:', { message: message.substring(0, 100), sessionId });

    // Get user from session (optional for demo)
    const userId = getUserFromRequest(req) || 'anonymous';

    // Get user memory for context
    const memory = getUserMemory(userId);

    // Prepare context from user memory
    const conversationContext = memory.conversations
      .slice(-3) // Last 3 conversations for context
      .map(conv => `User: ${conv.userMessage}\nAssistant: ${conv.agentResponse}`)
      .join('\n\n');

    // Create enhanced message with user context
    let enhancedMessage = message;
    if (conversationContext) {
      enhancedMessage = `Context from previous conversations:\n${conversationContext}\n\nCurrent question: ${message}`;
    }

    // Add user preferences to message
    if (memory.skillLevel !== 'intermediate') {
      enhancedMessage += `\n\nNote: User skill level is ${memory.skillLevel}`;
    }

    if (memory.technologyStack.length > 0) {
      enhancedMessage += `\nUser's technology stack: ${memory.technologyStack.join(', ')}`;
    }

    // Use AgentCore Gateway with user-specific session
    const userSessionId = sessionId || `${userId}-${Date.now()}`;
    const gatewayRequest = {
      message: enhancedMessage,
      sessionId: userSessionId,
      userId: userId,
      priority: 'normal',
      context: {
        messageCount: memory.conversations.length + 1,
        hasHistory: memory.conversations.length > 0,
        isNewSession: memory.conversations.length === 0,
        disableCache: true, // Rely on AgentCore native memory
        userSkillLevel: memory.skillLevel,
        userTechStack: memory.technologyStack
      }
    };

    console.log(`💬 Processing message for user ${userId} (${memory.conversations.length} previous conversations)`);

    const gatewayResponse = await agentCoreGateway.invoke(gatewayRequest);

    if (!gatewayResponse.success) {
      throw new Error(gatewayResponse.error || 'Gateway processing failed');
    }

    const agentResponse = gatewayResponse.response;
    const totalResponseTime = Date.now() - startTime;

    // Update user memory with this conversation
    updateUserMemory(userId, message, agentResponse);

    console.log(`✅ AgentCore response: ${gatewayResponse.metadata.responseTime}ms, total: ${totalResponseTime}ms`);

    res.json({
      success: true,
      response: agentResponse,
      sessionId: userSessionId,
      metadata: {
        responseTime: totalResponseTime,
        agentId: BEDROCK_AGENT_ID,
        region: AWS_REGION,
        userId: userId,
        memoryEnabled: true,
        conversationCount: memory.conversations.length,
        hasContext: conversationContext.length > 0,
        userSkillLevel: memory.skillLevel,
        cacheHit: gatewayResponse.metadata.cacheHit,
        retryCount: gatewayResponse.metadata.retryCount
      }
    });

  } catch (error) {
    const totalResponseTime = Date.now() - startTime;
    console.error('Chat error:', error);

    res.status(500).json({
      success: false,
      error: 'Chat failed: ' + error.message,
      details: error.stack,
      metadata: {
        responseTime: totalResponseTime,
        agentId: BEDROCK_AGENT_ID,
        region: AWS_REGION
      }
    });
  }
});

// Get user memory endpoint (for debugging)
app.get('/api/memory/:userId', (req, res) => {
  const { userId } = req.params;
  const memory = userMemory.get(userId);

  if (memory) {
    res.json({
      success: true,
      userId: userId,
      conversationCount: memory.conversations.length,
      skillLevel: memory.skillLevel,
      technologyStack: memory.technologyStack,
      createdAt: memory.createdAt,
      conversations: memory.conversations.slice(-5) // Last 5 for privacy
    });
  } else {
    res.status(404).json({
      success: false,
      error: 'User memory not found'
    });
  }
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Server error:', error);
  res.status(500).json({
    success: false,
    error: 'Internal server error',
    message: error.message
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint not found',
    path: req.originalUrl
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 DevOps KnowledgeOps Agent Server running on port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/api/health`);
  console.log(`🧠 AgentCore ID: ${BEDROCK_AGENT_ID}`);
  console.log(`💾 Memory enabled: Individual user sessions`);
  console.log(`🌐 CORS enabled for: http://localhost:3000`);
  console.log(`🔐 Authentication: ${cognitoClient ? 'Cognito + Session fallback' : 'Session-based (demo mode)'}`);
});

module.exports = app;