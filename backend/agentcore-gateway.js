/**
 * AgentCore Gateway Implementation (JavaScript)
 * Provides intelligent routing, caching, and optimization
 */

const { BedrockAgentRuntimeClient, InvokeAgentCommand } = require('@aws-sdk/client-bedrock-agent-runtime');
const { CloudWatchClient, PutMetricDataCommand } = require('@aws-sdk/client-cloudwatch');

class AgentCoreGateway {
    constructor(config) {
        this.config = {
            region: 'us-east-1',
            primaryAgentId: 'MNJESZYALW',
            primaryAliasId: 'TSTALIASID',
            enableCaching: true,
            enableMetrics: true,
            maxRetries: 2,
            timeoutMs: 30000,
            ...config
        };

        this.runtimeClient = new BedrockAgentRuntimeClient({ region: this.config.region });
        this.cloudWatchClient = new CloudWatchClient({ region: this.config.region });
        this.responseCache = new Map();
        this.requestQueue = new Map();

        console.log('🚀 AgentCore Gateway initialized with config:', {
            agentId: this.config.primaryAgentId,
            caching: this.config.enableCaching,
            metrics: this.config.enableMetrics
        });
    }

    async invoke(request) {
        const startTime = Date.now();

        try {
            // Check for duplicate requests
            if (this.requestQueue.has(request.sessionId)) {
                console.log(`🔄 Deduplicating request for session: ${request.sessionId}`);
                return await this.requestQueue.get(request.sessionId);
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

    async processRequest(request, startTime) {
        // Step 1: Check cache (unless disabled for this request)
        const shouldUseCache = this.config.enableCaching && !request.context?.disableCache;
        const cacheKey = this.generateCacheKey(request);
        
        if (shouldUseCache) {
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
        } else {
            console.log(`🚫 Cache disabled for this request (new session: ${request.context?.isNewSession})`);
        }

        // Step 2: Route to appropriate agent
        const agentConfig = this.selectAgent(request);

        // Step 3: Invoke agent with retry logic
        let lastError = null;
        let retryCount = 0;

        for (let attempt = 0; attempt <= this.config.maxRetries; attempt++) {
            try {
                const response = await this.invokeAgent(request, agentConfig, attempt);

                // Step 4: Cache successful response (unless disabled)
                if (shouldUseCache && response.success) {
                    this.cacheResponse(cacheKey, response.response, 300); // 5 min TTL
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
                lastError = error;
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

    selectAgent(request) {
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

    async invokeAgent(request, agentConfig, attempt) {
        const startTime = Date.now();

        try {
            // Optimize input based on attempt number
            const optimizedInput = this.optimizeInput(request.message, attempt);

            console.log(`🤖 Invoking Bedrock Agent ${agentConfig.agentId} (attempt ${attempt + 1})`);

            const command = new InvokeAgentCommand({
                agentId: agentConfig.agentId,
                agentAliasId: agentConfig.aliasId,
                sessionId: request.sessionId,
                inputText: optimizedInput,
                enableTrace: false // Disable trace for better performance
            });

            const response = await Promise.race([
                this.runtimeClient.send(command),
                new Promise((_, reject) =>
                    setTimeout(() => reject(new Error('Request timeout')), this.config.timeoutMs)
                )
            ]);

            // Enhanced response processing
            let fullResponse = '';
            let tokensUsed = 0;
            let chunks = 0;

            if (response.completion) {
                console.log(`📡 Processing streaming response...`);

                for await (const chunk of response.completion) {
                    chunks++;

                    if (chunk.chunk?.bytes) {
                        const text = new TextDecoder().decode(chunk.chunk.bytes);
                        fullResponse += text;
                        tokensUsed += text.split(/\s+/).length; // Better token estimate
                    }

                    // Handle other chunk types
                    if (chunk.trace) {
                        console.log(`🔍 Trace: ${JSON.stringify(chunk.trace)}`);
                    }

                    if (chunk.returnControl) {
                        console.log(`🎮 Return control: ${JSON.stringify(chunk.returnControl)}`);
                    }
                }

                console.log(`✅ Processed ${chunks} chunks, ${fullResponse.length} characters`);
            } else {
                console.log(`⚠️ No completion stream in response`);
            }

            // Validate response
            if (!fullResponse || fullResponse.trim().length === 0) {
                throw new Error('Empty response from Bedrock Agent');
            }

            const responseTime = Date.now() - startTime;

            return {
                success: true,
                response: fullResponse.trim(),
                sessionId: request.sessionId,
                metadata: {
                    responseTime,
                    agentUsed: agentConfig.agentId,
                    cacheHit: false,
                    retryCount: attempt,
                    tokensUsed,
                    confidence: 0.9,
                    chunksProcessed: chunks
                }
            };

        } catch (error) {
            const responseTime = Date.now() - startTime;

            console.error(`❌ Agent invocation failed (attempt ${attempt + 1}):`, error.message);

            // Enhanced error handling
            let errorMessage = error.message;

            if (error.name === 'ResourceNotFoundException') {
                errorMessage = `Bedrock Agent ${agentConfig.agentId} not found or not accessible`;
            } else if (error.name === 'AccessDeniedException') {
                errorMessage = 'Access denied - check IAM permissions for bedrock:InvokeAgent';
            } else if (error.name === 'ValidationException') {
                errorMessage = 'Invalid agent ID or alias ID format';
            } else if (error.name === 'ThrottlingException') {
                errorMessage = 'Request throttled - too many requests';
            } else if (error.message.includes('timeout')) {
                errorMessage = `Request timed out after ${this.config.timeoutMs}ms`;
            }

            throw new Error(errorMessage);
        }
    }

    optimizeInput(message, attempt) {
        // Input optimization based on attempt number
        if (attempt === 0) {
            return message; // First attempt - use original
        } else if (attempt === 1) {
            return `Please provide a comprehensive answer to: ${message}`; // Second attempt - be more explicit
        } else {
            return `This is important - please help with: ${message}`; // Final attempts - emphasize importance
        }
    }

    generateCacheKey(request) {
        // Generate cache key based on message content, user, and session
        const messageHash = Buffer.from(request.message).toString('base64').slice(0, 16);
        const userHash = request.userId ? Buffer.from(request.userId).toString('base64').slice(0, 8) : 'anon';
        const sessionHash = request.sessionId ? request.sessionId.slice(-8) : 'no-session';
        const contextHash = request.context ?
            Buffer.from(JSON.stringify(request.context)).toString('base64').slice(0, 8) :
            'no-context';

        return `${messageHash}-${userHash}-${sessionHash}-${contextHash}`;
    }

    getCachedResponse(cacheKey) {
        const cached = this.responseCache.get(cacheKey);

        if (cached && Date.now() - cached.timestamp < cached.ttl * 1000) {
            return cached;
        }

        if (cached) {
            this.responseCache.delete(cacheKey); // Remove expired
        }

        return null;
    }

    cacheResponse(cacheKey, response, ttlSeconds) {
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

    async recordMetrics(request, response, startTime) {
        if (!this.config.enableMetrics) return;

        try {
            const metrics = [
                {
                    MetricName: 'RequestCount',
                    Value: 1,
                    Unit: 'Count',
                    Dimensions: [
                        { Name: 'AgentId', Value: this.config.primaryAgentId },
                        { Name: 'Success', Value: response.success.toString() }
                    ]
                },
                {
                    MetricName: 'ResponseTime',
                    Value: response.metadata.responseTime,
                    Unit: 'Milliseconds',
                    Dimensions: [
                        { Name: 'AgentId', Value: this.config.primaryAgentId }
                    ]
                }
            ];

            if (response.metadata.tokensUsed) {
                metrics.push({
                    MetricName: 'TokensUsed',
                    Value: response.metadata.tokensUsed,
                    Unit: 'Count',
                    Dimensions: [
                        { Name: 'AgentId', Value: this.config.primaryAgentId }
                    ]
                });
            }

            if (response.metadata.cacheHit) {
                metrics.push({
                    MetricName: 'CacheHitRate',
                    Value: 1,
                    Unit: 'Count',
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
    async getMetrics() {
        return {
            cacheSize: this.responseCache.size,
            activeRequests: this.requestQueue.size,
            config: this.config
        };
    }

    clearCache() {
        this.responseCache.clear();
        console.log('🧹 Gateway cache cleared');
    }

    async healthCheck() {
        try {
            // Test basic agent connectivity
            const testRequest = {
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
                    error: error.message,
                    cacheSize: this.responseCache.size,
                    activeRequests: this.requestQueue.size
                }
            };
        }
    }
}

module.exports = { AgentCoreGateway };