import type { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { CognitoHelper } from './cognito-helper';

interface AuthRequest {
  action: 'signin' | 'signup' | 'confirm' | 'userinfo' | 'create-demo-user';
  username?: string;
  password?: string;
  email?: string;
  confirmationCode?: string;
  accessToken?: string;
}

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

    const request: AuthRequest = JSON.parse(event.body);

    switch (request.action) {
      case 'signin':
        if (!request.username || !request.password) {
          return {
            statusCode: 400,
            headers,
            body: JSON.stringify({ error: 'Username and password are required' }),
          };
        }
        
        const signInResult = await cognitoHelper.signIn(request.username, request.password);
        return {
          statusCode: signInResult.success ? 200 : 401,
          headers,
          body: JSON.stringify(signInResult),
        };

      case 'signup':
        if (!request.username || !request.password || !request.email) {
          return {
            statusCode: 400,
            headers,
            body: JSON.stringify({ error: 'Username, password, and email are required' }),
          };
        }
        
        const signUpResult = await cognitoHelper.signUp(request.username, request.password, request.email);
        return {
          statusCode: signUpResult.success ? 200 : 400,
          headers,
          body: JSON.stringify(signUpResult),
        };

      case 'confirm':
        if (!request.username || !request.confirmationCode) {
          return {
            statusCode: 400,
            headers,
            body: JSON.stringify({ error: 'Username and confirmation code are required' }),
          };
        }
        
        const confirmResult = await cognitoHelper.confirmSignUp(request.username, request.confirmationCode);
        return {
          statusCode: confirmResult.success ? 200 : 400,
          headers,
          body: JSON.stringify(confirmResult),
        };

      case 'userinfo':
        if (!request.accessToken) {
          return {
            statusCode: 400,
            headers,
            body: JSON.stringify({ error: 'Access token is required' }),
          };
        }
        
        const userInfo = await cognitoHelper.getUserInfo(request.accessToken);
        if (userInfo) {
          return {
            statusCode: 200,
            headers,
            body: JSON.stringify({ success: true, user: userInfo }),
          };
        } else {
          return {
            statusCode: 401,
            headers,
            body: JSON.stringify({ success: false, error: 'Invalid token' }),
          };
        }

      case 'create-demo-user':
        // For demo purposes - create a test user
        const demoResult = await cognitoHelper.createDemoUser(
          'demo-user',
          'demo@devops-agent.com',
          'DemoPass123!'
        );
        return {
          statusCode: demoResult.success ? 200 : 400,
          headers,
          body: JSON.stringify(demoResult),
        };

      default:
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: 'Invalid action' }),
        };
    }
  } catch (error: any) {
    console.error('Auth handler error:', error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ error: 'Internal server error' }),
    };
  }
};