import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { BedrockAgentManager } from '../bedrock/bedrock-client';
import { SessionManager } from '../session/session-manager';
import { MemoryManager } from '../memory/memory-manager';
import { ConversationUtils } from '../utils/conversation-utils';
import { CognitoHelper } from '../auth/cognito-helper';

interface ChatRequest {
  message: string;
  sessionId?: string;
}

const bedrockAgent = new BedrockAgentManager();
const sessionManager = new SessionManager();
const memoryManager = new MemoryManager();
const conversationUtils = new ConversationUtils();
const cognitoHelper = new CognitoHelper();

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  const headers = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization',
    'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
  };

  try {
    // Handle CORS preflight
    if (event.httpMethod === 'OPTIONS') {
      return {
        statusCode: 200,
        headers,
        body: '',
      };
    }

    if (!event.body) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'Request body is required' }),
      };
    }

    const request: ChatRequest = JSON.parse(event.body);
    const { message, sessionId } = request;

    if (!message?.trim()) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'Message is required' }),
      };
    }

    // Extract access token from Authorization header (optional for demo)
    const authHeader = event.headers.Authorization || event.headers.authorization;
    let userId = 'demo-user';
    
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const accessToken = authHeader.substring(7);
      const userInfo = await cognitoHelper.getUserInfo(accessToken);
      if (userInfo) {
        userId = userInfo.username;
      }
    }

    // Get or create session
    let currentSessionId = sessionId;
    if (!currentSessionId) {
      const newSession = await sessionManager.createSession(userId);
      currentSessionId = newSession.sessionId;
    }

    // Store user message
    await sessionManager.addMessage({
      sessionId: currentSessionId,
      userId,
      role: 'user',
      content: message,
    });

    // Build conversation context
    const conversationContext = await conversationUtils.buildConversationContext(currentSessionId);
    const contextSummary = conversationUtils.generateContextSummary(conversationContext);
    
    // Update memory with current context
    await memoryManager.storeContextualMemory(currentSessionId, userId, conversationContext);

    // Get conversation history for context
    const recentMessages = await sessionManager.getSessionMessages(currentSessionId, 10);
    const conversationHistory = conversationUtils.formatConversationHistory(recentMessages);

    // Generate response using Bedrock Agent
    const agentResponse = await bedrockAgent.invokeAgent(
      message,
      currentSessionId,
      `${contextSummary}\n\n${conversationHistory}`
    );

    if (!agentResponse.success) {
      return {
        statusCode: 500,
        headers,
        body: JSON.stringify({
          error: 'Failed to generate response',
          details: agentResponse.error,
        }),
      };
    }

    // Store assistant response
    await sessionManager.addMessage({
      sessionId: currentSessionId,
      userId,
      role: 'assistant',
      content: agentResponse.response!,
      metadata: agentResponse.metadata,
    });

    // Update conversation insights
    const extractedContext = conversationUtils.extractDevOpsContext(message);
    if (Object.keys(extractedContext).length > 0) {
      await memoryManager.updateConversationInsights(currentSessionId, userId, {
        commonTopics: extractedContext.currentTopic ? [extractedContext.currentTopic] : [],
        frequentTools: extractedContext.mentionedTools || [],
      });
    }

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({
        success: true,
        response: agentResponse.response,
        sessionId: currentSessionId,
        metadata: {
          responseTime: agentResponse.metadata?.responseTime || 0,
          confidence: agentResponse.metadata?.confidence || 0.9,
          context: contextSummary,
        },
      }),
    };

  } catch (error: any) {
    console.error('Chat processor error:', error);
    
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        error: 'Internal server error',
        message: error.message || 'An unexpected error occurred',
      }),
    };
  }
};