import { 
  CognitoIdentityProviderClient, 
  InitiateAuthCommand, 
  SignUpCommand, 
  ConfirmSignUpCommand,
  GetUserCommand,
  AdminCreateUserCommand,
  AdminSetUserPasswordCommand,
} from '@aws-sdk/client-cognito-identity-provider';

export interface AuthResult {
  success: boolean;
  accessToken?: string;
  idToken?: string;
  refreshToken?: string;
  error?: string;
}

export interface UserInfo {
  username: string;
  email?: string;
  attributes?: Record<string, string>;
}

export class CognitoHelper {
  private client: CognitoIdentityProviderClient;
  private userPoolId: string;
  private clientId: string;

  constructor(region: string = 'us-east-1') {
    this.client = new CognitoIdentityProviderClient({ region });
    this.userPoolId = process.env.USER_POOL_ID!;
    this.clientId = process.env.USER_POOL_CLIENT_ID!;
  }

  async signIn(username: string, password: string): Promise<AuthResult> {
    try {
      const command = new InitiateAuthCommand({
        AuthFlow: 'USER_PASSWORD_AUTH',
        ClientId: this.clientId,
        AuthParameters: {
          USERNAME: username,
          PASSWORD: password,
        },
      });

      const response = await this.client.send(command);
      
      if (response.AuthenticationResult) {
        return {
          success: true,
          accessToken: response.AuthenticationResult.AccessToken,
          idToken: response.AuthenticationResult.IdToken,
          refreshToken: response.AuthenticationResult.RefreshToken,
        };
      }

      return {
        success: false,
        error: 'Authentication failed',
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message || 'Sign in failed',
      };
    }
  }

  async signUp(username: string, password: string, email: string): Promise<AuthResult> {
    try {
      const command = new SignUpCommand({
        ClientId: this.clientId,
        Username: username,
        Password: password,
        UserAttributes: [
          {
            Name: 'email',
            Value: email,
          },
        ],
      });

      await this.client.send(command);
      
      return {
        success: true,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message || 'Sign up failed',
      };
    }
  }

  async confirmSignUp(username: string, confirmationCode: string): Promise<AuthResult> {
    try {
      const command = new ConfirmSignUpCommand({
        ClientId: this.clientId,
        Username: username,
        ConfirmationCode: confirmationCode,
      });

      await this.client.send(command);
      
      return {
        success: true,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message || 'Confirmation failed',
      };
    }
  }

  async getUserInfo(accessToken: string): Promise<UserInfo | null> {
    try {
      const command = new GetUserCommand({
        AccessToken: accessToken,
      });

      const response = await this.client.send(command);
      
      const attributes: Record<string, string> = {};
      response.UserAttributes?.forEach(attr => {
        if (attr.Name && attr.Value) {
          attributes[attr.Name] = attr.Value;
        }
      });

      return {
        username: response.Username!,
        email: attributes['email'],
        attributes,
      };
    } catch (error) {
      console.error('Failed to get user info:', error);
      return null;
    }
  }

  // Helper method for demo - create a demo user
  async createDemoUser(username: string, email: string, temporaryPassword: string): Promise<AuthResult> {
    try {
      // Create user
      const createCommand = new AdminCreateUserCommand({
        UserPoolId: this.userPoolId,
        Username: username,
        UserAttributes: [
          {
            Name: 'email',
            Value: email,
          },
          {
            Name: 'email_verified',
            Value: 'true',
          },
        ],
        TemporaryPassword: temporaryPassword,
        MessageAction: 'SUPPRESS', // Don't send welcome email for demo
      });

      await this.client.send(createCommand);

      // Set permanent password
      const setPasswordCommand = new AdminSetUserPasswordCommand({
        UserPoolId: this.userPoolId,
        Username: username,
        Password: temporaryPassword,
        Permanent: true,
      });

      await this.client.send(setPasswordCommand);

      return {
        success: true,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message || 'Failed to create demo user',
      };
    }
  }
}