import type { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { SessionManager } from './session-manager';
import { CognitoHelper } from '../auth/cognito-helper';

interface SessionRequest {
  action: 'create' | 'get' | 'list' | 'messages';
  sessionId?: string;
  accessToken?: string;
}

const sessionManager = new SessionManager();
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

    // Extract access token from Authorization header
    const authHeader = event.headers.Authorization || event.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return {
        statusCode: 401,
        headers,
        body: JSON.stringify({ error: 'Authorization token required' }),
      };
    }

    const accessToken = authHeader.substring(7); // Remove 'Bearer ' prefix

    // Verify token and get user info
    const userInfo = await cognitoHelper.getUserInfo(accessToken);
    if (!userInfo) {
      return {
        statusCode: 401,
        headers,
        body: JSON.stringify({ error: 'Invalid or expired token' }),
      };
    }

    if (!event.body) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'Request body is required' }),
      };
    }

    const request: SessionRequest = JSON.parse(event.body);

    switch (request.action) {
      case 'create':
        const newSession = await sessionManager.createSession(userInfo.username);
        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({
            success: true,
            session: newSession,
          }),
        };

      case 'get':
        if (!request.sessionId) {
          return {
            statusCode: 400,
            headers,
            body: JSON.stringify({ error: 'Session ID is required' }),
          };
        }

        const session = await sessionManager.getSession(request.sessionId);
        if (!session) {
          return {
            statusCode: 404,
            headers,
            body: JSON.stringify({ error: 'Session not found' }),
          };
        }

        // Verify session belongs to user
        if (session.userId !== userInfo.username) {
          return {
            statusCode: 403,
            headers,
            body: JSON.stringify({ error: 'Access denied' }),
          };
        }

        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({
            success: true,
            session,
          }),
        };

      case 'list':
        const sessions = await sessionManager.getUserSessions(userInfo.username);
        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({
            success: true,
            sessions,
          }),
        };

      case 'messages':
        if (!request.sessionId) {
          return {
            statusCode: 400,
            headers,
            body: JSON.stringify({ error: 'Session ID is required' }),
          };
        }

        // Verify session exists and belongs to user
        const messageSession = await sessionManager.getSession(request.sessionId);
        if (!messageSession || messageSession.userId !== userInfo.username) {
          return {
            statusCode: 403,
            headers,
            body: JSON.stringify({ error: 'Access denied' }),
          };
        }

        const messages = await sessionManager.getSessionMessages(request.sessionId);
        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({
            success: true,
            messages,
          }),
        };

      default:
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: 'Invalid action' }),
        };
    }
  } catch (error: any) {
    console.error('Session handler error:', error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ error: 'Internal server error' }),
    };
  }
};