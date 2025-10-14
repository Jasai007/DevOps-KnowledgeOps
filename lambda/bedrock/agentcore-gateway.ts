/**
 * AgentCore Gateway Implementation
 * Provides intelligent routing, caching, and optimization
 */

import {
  BedrockAgentRuntimeClient,
  InvokeAgentCommand
} from '@aws-sdk/client-bedrock-agent-runtime';
import { CloudWatchClient, PutMetricDataCommand } from '@aws-sdk/client-cloudwatch';

export interface GatewayConfig {
  region: string;
  primaryAgentId: string;
  primaryAliasId: string;
  fallbackAgentId?: string;
  fallbackAliasId?: string;
  enableCaching: boolean;
  enableMetrics: boolean;
  maxRetries: number;
  timeoutMs: number;
}

export interface GatewayRequest {
  message: string;
  sessionId: string;
  userId?: string;
  priority?: 'low' | 'normal' | 'high';
  context?: Record<string, any>;
}

export interface GatewayResponse {
  success: boolean;
  response?: string;
  sessionId: string;
  metadata: {
    responseTime: number;
    agentUsed: string;
    cacheHit: boolean;
    retryCount: number;
    confidence?: number;
    tokensUsed?: number;
  };
  error?: string;
}

export class AgentCoreGateway {
  private runtimeClient: BedrockAgentRuntimeClient;
  private cloudWatchClient: CloudWatchClient;
  private config: GatewayConfig;
  private responseCache: Map<string, { response: string; timestamp: number; ttl: number }>;
  private requestQueue: Map<string, Promise<GatewayResponse>>;

  constructor(config: GatewayConfig) {
    this.config = config;
    this.runtimeClient = new BedrockAgentRuntimeClient({ region: config.region });
    this.cloudWatchClient = new CloudWatchClient({ region: config.region });
    this.responseCache = new Map();
    this.requestQueue = new Map();
  }

  async invoke(request: GatewayRequest): Promise<GatewayResponse> {
    const startTime = Date.now();

    try {
      // Check for duplicate requests
      if (this.requestQueue.has(request.sessionId)) {
        console.log(`🔄 Deduplicating request for session: ${request.sessionId}`);
        return await this.requestQueue.get(request.sessionId)!;
      }

      // Create promise for this request
      const requestPromise = this.processRequest(request, startTime);
      this.requestQueue.set(request.sessionId, requestPromise);

      const result = await requestPromise;

      // Clean up
      this.requestQueue.delete(request.sessionId);

      return result;
    } catch (error) {
      this.requestQueue.delete(request.sessionId);
      throw error;
    }
  }

  private async processRequest(request: GatewayRequest, startTime: number): Promise<GatewayResponse> {
    // Step 1: Check cache
    const cacheKey = this.generateCacheKey(request);
    const cachedResponse = this.getCachedResponse(cacheKey);

    if (cachedResponse) {
      console.log(`💾 Cache hit for request: ${cacheKey}`);
      return {
        success: true,
        response: cachedResponse.response,
        sessionId: request.sessionId,
        metadata: {
          responseTime: Date.now() - startTime,
          agentUsed: 'cache',
          cacheHit: true,
          retryCount: 0,
        }
      };
    }

    // Step 2: Route to appropriate agent
    const agentConfig = this.selectAgent(request);

    // Step 3: Invoke agent with retry logic
    let lastError: Error | null = null;
    let retryCount = 0;

    for (let attempt = 0; attempt <= this.config.maxRetries; attempt++) {
      try {
        const response = await this.invokeAgent(request, agentConfig, attempt);

        // Step 4: Cache successful response
        if (this.config.enableCaching && response.success) {
          this.cacheResponse(cacheKey, response.response!, 300); // 5 min TTL
        }

        // Step 5: Record metrics
        if (this.config.enableMetrics) {
          await this.recordMetrics(request, response, startTime);
        }

        return {
          ...response,
          metadata: {
            ...response.metadata,
            retryCount,
            cacheHit: false,
          }
        };

      } catch (error) {
        lastError = error as Error;
        retryCount = attempt + 1;

        if (attempt < this.config.maxRetries) {
          const delay = Math.pow(2, attempt) * 1000; // Exponential backoff
          console.log(`⚠️ Attempt ${attempt + 1} failed, retrying in ${delay}ms...`);
          await new Promise(resolve => setTimeout(resolve, delay));
        }
      }
    }

    // All retries failed
    return {
      success: false,
      sessionId: request.sessionId,
      error: `All ${this.config.maxRetries + 1} attempts failed: ${lastError?.message}`,
      metadata: {
        responseTime: Date.now() - startTime,
        agentUsed: agentConfig.agentId,
        cacheHit: false,
        retryCount,
      }
    };
  }

  private selectAgent(_request: GatewayRequest): { agentId: string; aliasId: string } {
    // Intelligent agent selection based on request characteristics

    // For now, use primary agent, but this could be enhanced with:
    // - Load balancing across multiple agents
    // - Specialized agents for different topics
    // - Priority-based routing

    return {
      agentId: this.config.primaryAgentId,
      aliasId: this.config.primaryAliasId
    };
  }

  private async invokeAgent(
    request: GatewayRequest,
    agentConfig: { agentId: string; aliasId: string },
    attempt: number
  ): Promise<GatewayResponse> {
    const startTime = Date.now();

    // Optimize input based on attempt number
    const optimizedInput = this.optimizeInput(request.message, attempt);

    const command = new InvokeAgentCommand({
      agentId: agentConfig.agentId,
      agentAliasId: agentConfig.aliasId,
      sessionId: request.sessionId,
      inputText: optimizedInput,
      enableTrace: true
    });

    const response = await Promise.race([
      this.runtimeClient.send(command),
      new Promise((_, reject) =>
        setTimeout(() => reject(new Error('Request timeout')), this.config.timeoutMs)
      )
    ]) as any;

    // Process streaming response
    let fullResponse = '';
    let tokensUsed = 0;

    if (response.completion) {
      for await (const chunk of response.completion) {
        if (chunk.chunk?.bytes) {
          const text = new TextDecoder().decode(chunk.chunk.bytes);
          fullResponse += text;
          tokensUsed += text.split(' ').length; // Rough token estimate
        }
      }
    }

    const responseTime = Date.now() - startTime;

    return {
      success: true,
      response: fullResponse || 'No response received',
      sessionId: request.sessionId,
      metadata: {
        responseTime,
        agentUsed: agentConfig.agentId,
        cacheHit: false,
        retryCount: attempt,
        tokensUsed,
        confidence: 0.9
      }
    };
  }

  private optimizeInput(message: string, attempt: number): string {
    // Input optimization based on attempt number
    if (attempt === 0) {
      return message; // First attempt - use original
    } else if (attempt === 1) {
      return `Please provide a comprehensive answer to: ${message}`; // Second attempt - be more explicit
    } else {
      return `This is important - please help with: ${message}`; // Final attempts - emphasize importance
    }
  }

  private generateCacheKey(request: GatewayRequest): string {
    // Generate cache key based on message content and user context
    const messageHash = btoa(request.message).slice(0, 16);
    const contextHash = request.context ?
      btoa(JSON.stringify(request.context)).slice(0, 8) :
      'no-context';

    return `${messageHash}-${contextHash}`;
  }

  private getCachedResponse(cacheKey: string): { response: string; timestamp: number; ttl: number } | null {
    const cached = this.responseCache.get(cacheKey);

    if (cached && Date.now() - cached.timestamp < cached.ttl * 1000) {
      return cached;
    }

    if (cached) {
      this.responseCache.delete(cacheKey); // Remove expired
    }

    return null;
  }

  private cacheResponse(cacheKey: string, response: string, ttlSeconds: number): void {
    if (!this.config.enableCaching) return;

    this.responseCache.set(cacheKey, {
      response,
      timestamp: Date.now(),
      ttl: ttlSeconds
    });

    // Cleanup old entries (keep cache size manageable)
    if (this.responseCache.size > 1000) {
      const oldestKey = this.responseCache.keys().next().value;
      if (oldestKey) {
        this.responseCache.delete(oldestKey);
      }
    }
  }

  private async recordMetrics(
    _request: GatewayRequest,
    response: GatewayResponse,
    _startTime: number
  ): Promise<void> {
    if (!this.config.enableMetrics) return;

    try {
      const metrics = [
        {
          MetricName: 'RequestCount',
          Value: 1,
          Unit: 'Count' as const,
          Dimensions: [
            { Name: 'AgentId', Value: this.config.primaryAgentId },
            { Name: 'Success', Value: response.success.toString() }
          ]
        },
        {
          MetricName: 'ResponseTime',
          Value: response.metadata.responseTime,
          Unit: 'Milliseconds' as const,
          Dimensions: [
            { Name: 'AgentId', Value: this.config.primaryAgentId }
          ]
        }
      ];

      if (response.metadata.tokensUsed) {
        metrics.push({
          MetricName: 'TokensUsed',
          Value: response.metadata.tokensUsed,
          Unit: 'Count' as const,
          Dimensions: [
            { Name: 'AgentId', Value: this.config.primaryAgentId }
          ]
        });
      }

      if (response.metadata.cacheHit) {
        metrics.push({
          MetricName: 'CacheHitRate',
          Value: 1,
          Unit: 'Count' as const,
          Dimensions: [
            { Name: 'AgentId', Value: this.config.primaryAgentId }
          ]
        });
      }

      await this.cloudWatchClient.send(new PutMetricDataCommand({
        Namespace: 'AgentCore/Gateway',
        MetricData: metrics.map(metric => ({
          ...metric,
          Timestamp: new Date()
        }))
      }));

    } catch (error) {
      console.error('Failed to record metrics:', error);
      // Don't fail the request if metrics fail
    }
  }

  // Utility methods
  async getMetrics(): Promise<any> {
    return {
      cacheSize: this.responseCache.size,
      activeRequests: this.requestQueue.size,
      config: this.config
    };
  }

  clearCache(): void {
    this.responseCache.clear();
    console.log('🧹 Gateway cache cleared');
  }

  async healthCheck(): Promise<{ status: string; details: any }> {
    try {
      // Test basic agent connectivity
      const testRequest: GatewayRequest = {
        message: 'Health check',
        sessionId: `health-${Date.now()}`
      };

      const startTime = Date.now();
      const response = await this.processRequest(testRequest, startTime);

      return {
        status: response.success ? 'healthy' : 'unhealthy',
        details: {
          responseTime: response.metadata.responseTime,
          cacheSize: this.responseCache.size,
          activeRequests: this.requestQueue.size,
          lastError: response.error
        }
      };
    } catch (error) {
      return {
        status: 'unhealthy',
        details: {
          error: (error as Error).message,
          cacheSize: this.responseCache.size,
          activeRequests: this.requestQueue.size
        }
      };
    }
  }
}