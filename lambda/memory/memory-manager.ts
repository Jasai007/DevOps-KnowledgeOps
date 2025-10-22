/**
 * AgentCore Memory Manager for persistent conversation context
 */

import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import {
  DynamoDBDocumentClient,
  PutCommand,
  GetCommand,
  QueryCommand
} from '@aws-sdk/lib-dynamodb';

export interface ConversationMemory {
  sessionId: string;
  userId: string;
  memoryType: 'context' | 'preferences' | 'history' | 'insights';
  memoryKey: string;
  memoryValue: unknown;
  timestamp: number;
  expiresAt?: number;
  confidence?: number;
  source?: string;
}

export interface UserPreferences {
  experienceLevel?: 'beginner' | 'intermediate' | 'advanced';
  preferredTools?: string[];
  cloudProviders?: string[];
  communicationStyle?: 'detailed' | 'concise' | 'step-by-step';
  focusAreas?: string[];
}

export interface ConversationInsights {
  commonTopics: string[];
  frequentTools: string[];
  problemPatterns: string[];
  successfulSolutions: string[];
  learningProgress: {
    topic: string;
    level: number;
    lastUpdated: number;
  }[];
}

export class MemoryManager {
  private client: DynamoDBDocumentClient;
  private tableName: string;
  private retentionDays: number;

  constructor(region: string = 'us-east-1', retentionDays: number = 7) {
    const dynamoClient = new DynamoDBClient({ region });
    this.client = DynamoDBDocumentClient.from(dynamoClient);

    // Use environment variables with fallback
    const getEnvVar = (name: string): string | undefined => {
      try {
        return (globalThis as any)?.process?.env?.[name];
      } catch {
        return undefined;
      }
    };

    const memoryTableName = getEnvVar('MEMORY_TABLE_NAME');
    const chatTableName = getEnvVar('CHAT_TABLE_NAME');
    this.tableName = memoryTableName || chatTableName || 'devops-agent-memory';

    this.retentionDays = retentionDays;
  }

  async storeMemory(memory: Omit<ConversationMemory, 'timestamp' | 'expiresAt'>): Promise<void> {
    const now = Date.now();
    const expiresAt = now + (this.retentionDays * 24 * 60 * 60 * 1000);

    const fullMemory: ConversationMemory = {
      ...memory,
      timestamp: now,
      expiresAt,
    };

    try {
      await this.client.send(new PutCommand({
        TableName: this.tableName,
        Item: {
          sessionId: `MEMORY_${memory.sessionId}`,
          messageId: `${memory.memoryType}_${memory.memoryKey}`,
          userId: fullMemory.userId,
          memoryType: fullMemory.memoryType,
          memoryKey: fullMemory.memoryKey,
          memoryValue: fullMemory.memoryValue,
          timestamp: fullMemory.timestamp,
          expiresAt: fullMemory.expiresAt,
          confidence: fullMemory.confidence,
          source: fullMemory.source,
        },
      }));
    } catch (error) {
      console.error('Error storing memory:', error);
    }
  }

  async getMemory(sessionId: string, memoryType: string, memoryKey: string): Promise<ConversationMemory | null> {
    try {
      const response = await this.client.send(new GetCommand({
        TableName: this.tableName,
        Key: {
          sessionId: `MEMORY_${sessionId}`,
          messageId: `${memoryType}_${memoryKey}`,
        },
      }));

      if (response.Item) {
        // Extract the memory data, excluding DynamoDB keys
        const item = response.Item;
        return {
          sessionId: item.sessionId?.replace('MEMORY_', '') || '',
          userId: item.userId || '',
          memoryType: item.memoryType || 'context',
          memoryKey: item.memoryKey || '',
          memoryValue: item.memoryValue,
          timestamp: item.timestamp || 0,
          expiresAt: item.expiresAt,
          confidence: item.confidence,
          source: item.source,
        } as ConversationMemory;
      }

      return null;
    } catch (error) {
      console.error('Error getting memory:', error);
      return null;
    }
  }

  async getSessionMemories(sessionId: string, memoryType?: string): Promise<ConversationMemory[]> {
    try {
      const params: any = {
        TableName: this.tableName,
        KeyConditionExpression: 'sessionId = :sessionId',
        ExpressionAttributeValues: {
          ':sessionId': `MEMORY_${sessionId}`,
        },
      };

      if (memoryType) {
        params.FilterExpression = 'begins_with(messageId, :memoryType)';
        params.ExpressionAttributeValues[':memoryType'] = memoryType;
      }

      const response = await this.client.send(new QueryCommand(params));

      return (response.Items || []).map(item => ({
        sessionId: item.sessionId?.replace('MEMORY_', '') || '',
        userId: item.userId || '',
        memoryType: item.memoryType || 'context',
        memoryKey: item.memoryKey || '',
        memoryValue: item.memoryValue,
        timestamp: item.timestamp || 0,
        expiresAt: item.expiresAt,
        confidence: item.confidence,
        source: item.source,
      } as ConversationMemory));
    } catch (error) {
      console.error('Error getting session memories:', error);
      return [];
    }
  }

  async updateUserPreferences(userId: string, preferences: Partial<UserPreferences>): Promise<void> {
    const existing = await this.getMemory('USER_GLOBAL', 'preferences', userId);
    const existingPrefs = (existing?.memoryValue as UserPreferences) || {};
    const updated = { ...existingPrefs, ...preferences };

    await this.storeMemory({
      sessionId: 'USER_GLOBAL',
      userId,
      memoryType: 'preferences',
      memoryKey: userId,
      memoryValue: updated,
      confidence: 1.0,
      source: 'user_input',
    });
  }

  async getUserPreferences(userId: string): Promise<UserPreferences> {
    const memory = await this.getMemory('USER_GLOBAL', 'preferences', userId);
    return (memory?.memoryValue as UserPreferences) || {};
  }

  async updateConversationInsights(sessionId: string, userId: string, insights: Partial<ConversationInsights>): Promise<void> {
    const existing = await this.getMemory(sessionId, 'insights', 'conversation');
    const existingInsights = (existing?.memoryValue as ConversationInsights) || {
      commonTopics: [],
      frequentTools: [],
      problemPatterns: [],
      successfulSolutions: [],
      learningProgress: [],
    };
    const updated = this.mergeInsights(existingInsights, insights);

    await this.storeMemory({
      sessionId,
      userId,
      memoryType: 'insights',
      memoryKey: 'conversation',
      memoryValue: updated,
      confidence: 0.8,
      source: 'ai_analysis',
    });
  }

  async getConversationInsights(sessionId: string): Promise<ConversationInsights> {
    const memory = await this.getMemory(sessionId, 'insights', 'conversation');
    return (memory?.memoryValue as ConversationInsights) || {
      commonTopics: [],
      frequentTools: [],
      problemPatterns: [],
      successfulSolutions: [],
      learningProgress: [],
    };
  }

  async storeContextualMemory(sessionId: string, userId: string, context: Record<string, unknown>): Promise<void> {
    await this.storeMemory({
      sessionId,
      userId,
      memoryType: 'context',
      memoryKey: 'current',
      memoryValue: context,
      confidence: 0.9,
      source: 'conversation_analysis',
    });
  }

  async getContextualMemory(sessionId: string): Promise<Record<string, unknown>> {
    const memory = await this.getMemory(sessionId, 'context', 'current');
    return (memory?.memoryValue as Record<string, unknown>) || {};
  }

  async generateMemorySummary(sessionId: string): Promise<string> {
    const memories = await this.getSessionMemories(sessionId);

    if (memories.length === 0) {
      return 'No previous conversation context available.';
    }

    const context = (memories.find(m => m.memoryType === 'context')?.memoryValue as Record<string, unknown>) || {};
    const insightsMemory = memories.find(m => m.memoryType === 'insights')?.memoryValue;
    const insights: ConversationInsights = insightsMemory ? insightsMemory as ConversationInsights : {
      commonTopics: [],
      frequentTools: [],
      problemPatterns: [],
      successfulSolutions: [],
      learningProgress: []
    };

    const summary: string[] = [];

    if (context.currentTopic && typeof context.currentTopic === 'string') {
      summary.push(`Current focus: ${context.currentTopic}`);
    }

    if (Array.isArray(context.mentionedTools) && context.mentionedTools.length > 0) {
      summary.push(`Tools discussed: ${context.mentionedTools.join(', ')}`);
    }

    if (context.infrastructureContext &&
      typeof context.infrastructureContext === 'object' &&
      context.infrastructureContext !== null &&
      'cloudProvider' in context.infrastructureContext) {
      const infraContext = context.infrastructureContext as { cloudProvider: string };
      summary.push(`Cloud context: ${infraContext.cloudProvider}`);
    }

    if (insights.commonTopics && Array.isArray(insights.commonTopics) && insights.commonTopics.length > 0) {
      summary.push(`Common topics: ${insights.commonTopics.slice(0, 3).join(', ')}`);
    }

    return summary.length > 0
      ? `Previous context: ${summary.join('; ')}`
      : 'New conversation starting.';
  }

  private mergeInsights(existing: ConversationInsights, updates: Partial<ConversationInsights>): ConversationInsights {
    return {
      commonTopics: this.mergeArrays(existing.commonTopics || [], updates.commonTopics || []),
      frequentTools: this.mergeArrays(existing.frequentTools || [], updates.frequentTools || []),
      problemPatterns: this.mergeArrays(existing.problemPatterns || [], updates.problemPatterns || []),
      successfulSolutions: this.mergeArrays(existing.successfulSolutions || [], updates.successfulSolutions || []),
      learningProgress: updates.learningProgress || existing.learningProgress || [],
    };
  }

  private mergeArrays(existing: string[], updates: string[]): string[] {
    const combined = [...existing, ...updates];
    const counts = combined.reduce((acc, item) => {
      acc[item] = (acc[item] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);

    return Object.entries(counts)
      .sort(([, a], [, b]) => b - a)
      .slice(0, 10) // Keep top 10
      .map(([item]) => item);
  }

  async cleanupExpiredMemories(): Promise<void> {
    // This would typically be handled by DynamoDB TTL in production
    // For demo purposes, we'll implement a simple cleanup
    console.log('Memory cleanup would run here in production');
  }
}