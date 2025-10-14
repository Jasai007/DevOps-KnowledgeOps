import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { 
  DynamoDBDocumentClient, 
  PutCommand, 
  GetCommand, 
  UpdateCommand, 
  QueryCommand 
} from '@aws-sdk/lib-dynamodb';
import { v4 as uuidv4 } from 'uuid';

export interface ChatSession {
  sessionId: string;
  userId: string;
  createdAt: number;
  lastActivity: number;
  messageCount: number;
  context?: {
    currentTopic?: string;
    mentionedTools?: string[];
    infrastructureContext?: any;
  };
}

export interface ChatMessage {
  sessionId: string;
  messageId: string;
  userId: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: number;
  metadata?: {
    responseTime?: number;
    confidence?: number;
    sources?: string[];
  };
}

export class SessionManager {
  private client: DynamoDBDocumentClient;
  private tableName: string;

  constructor(region: string = 'us-east-1') {
    const dynamoClient = new DynamoDBClient({ region });
    this.client = DynamoDBDocumentClient.from(dynamoClient);
    this.tableName = process.env.CHAT_TABLE_NAME!;
  }

  async createSession(userId: string): Promise<ChatSession> {
    const sessionId = uuidv4();
    const now = Date.now();
    
    const session: ChatSession = {
      sessionId,
      userId,
      createdAt: now,
      lastActivity: now,
      messageCount: 0,
    };

    await this.client.send(new PutCommand({
      TableName: this.tableName,
      Item: {
        ...session,
        messageId: 'SESSION_METADATA', // Special messageId for session metadata
      },
    }));

    return session;
  }

  async getSession(sessionId: string): Promise<ChatSession | null> {
    try {
      const response = await this.client.send(new GetCommand({
        TableName: this.tableName,
        Key: {
          sessionId,
          messageId: 'SESSION_METADATA',
        },
      }));

      if (response.Item) {
        const { messageId, ...session } = response.Item;
        return session as ChatSession;
      }
      
      return null;
    } catch (error) {
      console.error('Error getting session:', error);
      return null;
    }
  }

  async updateSessionActivity(sessionId: string): Promise<void> {
    try {
      await this.client.send(new UpdateCommand({
        TableName: this.tableName,
        Key: {
          sessionId,
          messageId: 'SESSION_METADATA',
        },
        UpdateExpression: 'SET lastActivity = :now, messageCount = messageCount + :inc',
        ExpressionAttributeValues: {
          ':now': Date.now(),
          ':inc': 1,
        },
      }));
    } catch (error) {
      console.error('Error updating session activity:', error);
    }
  }

  async addMessage(message: Omit<ChatMessage, 'messageId' | 'timestamp'>): Promise<ChatMessage> {
    const messageId = uuidv4();
    const timestamp = Date.now();
    
    const fullMessage: ChatMessage = {
      ...message,
      messageId,
      timestamp,
    };

    await this.client.send(new PutCommand({
      TableName: this.tableName,
      Item: fullMessage,
    }));

    // Update session activity
    await this.updateSessionActivity(message.sessionId);

    return fullMessage;
  }

  async getSessionMessages(sessionId: string, limit: number = 50): Promise<ChatMessage[]> {
    try {
      const response = await this.client.send(new QueryCommand({
        TableName: this.tableName,
        KeyConditionExpression: 'sessionId = :sessionId AND messageId <> :metadata',
        ExpressionAttributeValues: {
          ':sessionId': sessionId,
          ':metadata': 'SESSION_METADATA',
        },
        ScanIndexForward: true, // Sort by messageId (timestamp order)
        Limit: limit,
      }));

      return (response.Items || []) as ChatMessage[];
    } catch (error) {
      console.error('Error getting session messages:', error);
      return [];
    }
  }

  async getUserSessions(userId: string, limit: number = 10): Promise<ChatSession[]> {
    try {
      const response = await this.client.send(new QueryCommand({
        TableName: this.tableName,
        IndexName: 'UserIndex',
        KeyConditionExpression: 'userId = :userId',
        ScanIndexForward: false, // Most recent first
        Limit: limit,
        FilterExpression: 'messageId = :metadata',
        ExpressionAttributeValues: {
          ':userId': userId,
          ':metadata': 'SESSION_METADATA',
        },
      }));

      return (response.Items || []).map(item => {
        const { messageId, ...session } = item;
        return session as ChatSession;
      });
    } catch (error) {
      console.error('Error getting user sessions:', error);
      return [];
    }
  }

  async updateSessionContext(sessionId: string, context: any): Promise<void> {
    try {
      await this.client.send(new UpdateCommand({
        TableName: this.tableName,
        Key: {
          sessionId,
          messageId: 'SESSION_METADATA',
        },
        UpdateExpression: 'SET #context = :context',
        ExpressionAttributeNames: {
          '#context': 'context',
        },
        ExpressionAttributeValues: {
          ':context': context,
        },
      }));
    } catch (error) {
      console.error('Error updating session context:', error);
    }
  }
}