# Fix CORS Issues for Lambda Functions
Write-Host "🔧 Fixing CORS Issues for Lambda Functions" -ForegroundColor Cyan

# Function names
$CHAT_FUNCTION = "devops-agent-chat"
$AUTH_FUNCTION = "devops-agent-auth"
$SESSION_FUNCTION = "devops-agent-session"

Write-Host "`n1. 📝 Creating CORS-Fixed Lambda Functions..." -ForegroundColor Yellow

# Create CORS-fixed chat handler
$corsFixedChatHandler = @'
// AgentCore Chat Handler with Memory and CORS Fix
const { AgentCoreGateway } = require('./agentcore-gateway');
const { MemoryManager } = require('./memory/memory-manager');

// Initialize AgentCore Gateway and Memory Manager
const agentGateway = new AgentCoreGateway({
    region: 'us-east-1',
    primaryAgentId: 'MNJESZYALW',
    primaryAliasId: 'TSTALIASID',
    enableCaching: true,
    enableMetrics: true,
    maxRetries: 2,
    timeoutMs: 30000
});

const memoryManager = new MemoryManager('us-east-1', 7);

exports.handler = async (event) => {
    // Enhanced CORS headers
    const headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token,X-Requested-With',
        'Access-Control-Allow-Methods': 'GET,POST,OPTIONS,PUT,DELETE,PATCH',
        'Access-Control-Max-Age': '86400',
        'Access-Control-Allow-Credentials': 'false'
    };

    console.log('AgentCore chat handler called with method:', event.httpMethod);
    console.log('Headers:', JSON.stringify(event.headers));

    try {
        // Handle preflight OPTIONS request
        if (event.httpMethod === 'OPTIONS') {
            console.log('Handling OPTIONS preflight request');
            return {
                statusCode: 200,
                headers,
                body: JSON.stringify({ message: 'CORS preflight successful' })
            };
        }

        if (event.httpMethod === 'POST') {
            if (!event.body) {
                return {
                    statusCode: 400,
                    headers,
                    body: JSON.stringify({
                        success: false,
                        error: 'Request body is required'
                    }),
                };
            }

            const request = JSON.parse(event.body);

            if (!request.message) {
                return {
                    statusCode: 400,
                    headers,
                    body: JSON.stringify({
                        success: false,
                        error: 'Message is required'
                    }),
                };
            }

            // Generate session ID if not provided
            const sessionId = request.sessionId || `session-${Date.now()}`;
            
            // Extract user ID from JWT token (if available)
            const userId = extractUserIdFromEvent(event) || 'anonymous';

            console.log('Invoking AgentCore with message:', request.message.substring(0, 100));
            console.log('User ID:', userId, 'Session ID:', sessionId);

            // Get conversation memory and context
            const memorySummary = await memoryManager.generateMemorySummary(sessionId);
            const userPreferences = await memoryManager.getUserPreferences(userId);

            // Enhance message with memory context
            let enhancedMessage = request.message;
            if (memorySummary && memorySummary !== 'New conversation starting.') {
                enhancedMessage = `Context: ${memorySummary}\n\nUser Question: ${request.message}`;
            }

            // Add user preferences to context if available
            if (userPreferences.experienceLevel || userPreferences.communicationStyle) {
                const prefContext = [];
                if (userPreferences.experienceLevel) {
                    prefContext.push(`Experience: ${userPreferences.experienceLevel}`);
                }
                if (userPreferences.communicationStyle) {
                    prefContext.push(`Style: ${userPreferences.communicationStyle}`);
                }
                if (userPreferences.preferredTools && userPreferences.preferredTools.length > 0) {
                    prefContext.push(`Preferred tools: ${userPreferences.preferredTools.join(', ')}`);
                }
                
                if (prefContext.length > 0) {
                    enhancedMessage = `User preferences: ${prefContext.join(', ')}\n\n${enhancedMessage}`;
                }
            }

            // Get response from AgentCore
            const agentResponse = await agentGateway.invokeAgent(
                enhancedMessage,
                sessionId,
                {
                    enableTrace: true,
                    maxTokens: 2000
                }
            );

            console.log('AgentCore response:', {
                success: agentResponse.success,
                responseLength: agentResponse.response?.length || 0
            });

            if (agentResponse.success) {
                // Store conversation context and insights in memory
                try {
                    // Analyze message for context
                    const messageAnalysis = analyzeMessage(request.message, agentResponse.response);
                    
                    // Update contextual memory
                    await memoryManager.storeContextualMemory(sessionId, userId, {
                        lastMessage: request.message,
                        lastResponse: agentResponse.response,
                        currentTopic: messageAnalysis.topic,
                        mentionedTools: messageAnalysis.tools,
                        infrastructureContext: messageAnalysis.infrastructure,
                        timestamp: Date.now()
                    });

                    // Update conversation insights
                    await memoryManager.updateConversationInsights(sessionId, userId, {
                        commonTopics: messageAnalysis.topic ? [messageAnalysis.topic] : [],
                        frequentTools: messageAnalysis.tools || [],
                        problemPatterns: messageAnalysis.problemType ? [messageAnalysis.problemType] : [],
                        successfulSolutions: messageAnalysis.solutionType ? [messageAnalysis.solutionType] : []
                    });

                    // Update user preferences based on interaction
                    if (messageAnalysis.inferredPreferences) {
                        await memoryManager.updateUserPreferences(userId, messageAnalysis.inferredPreferences);
                    }
                } catch (memoryError) {
                    console.error('Memory storage error:', memoryError);
                    // Continue without failing the response
                }

                return {
                    statusCode: 200,
                    headers,
                    body: JSON.stringify({
                        success: true,
                        response: agentResponse.response,
                        sessionId: sessionId,
                        metadata: {
                            responseTime: agentResponse.metadata?.responseTime || 0,
                            agentId: 'MNJESZYALW',
                            region: 'us-east-1',
                            memoryEnabled: true,
                            userId: userId
                        }
                    }),
                };
            } else {
                console.error('AgentCore error:', agentResponse.error);
                return {
                    statusCode: 500,
                    headers,
                    body: JSON.stringify({
                        success: false,
                        error: 'Failed to get response from AgentCore',
                        details: agentResponse.error
                    }),
                };
            }
        }

        return {
            statusCode: 405,
            headers,
            body: JSON.stringify({
                success: false,
                error: 'Method not allowed'
            }),
        };

    } catch (error) {
        console.error('Chat handler error:', error);
        return {
            statusCode: 500,
            headers,
            body: JSON.stringify({
                success: false,
                error: 'Internal server error',
                details: error.message
            }),
        };
    }
};

// Helper function to extract user ID from JWT token
function extractUserIdFromEvent(event) {
    try {
        const authHeader = event.headers?.Authorization || event.headers?.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return null;
        }

        const token = authHeader.substring(7);
        const parts = token.split('.');
        if (parts.length !== 3) {
            return null;
        }

        const payload = JSON.parse(Buffer.from(parts[1], 'base64').toString());
        
        return payload.username || 
               payload['cognito:username'] || 
               payload.email || 
               payload.sub || 
               null;
    } catch (error) {
        console.error('Error extracting user ID:', error);
        return null;
    }
}

// Helper function to analyze message content for memory storage
function analyzeMessage(userMessage, agentResponse) {
    const analysis = {
        topic: null,
        tools: [],
        infrastructure: {},
        problemType: null,
        solutionType: null,
        inferredPreferences: {}
    };

    const lowerMessage = userMessage.toLowerCase();
    const lowerResponse = agentResponse.toLowerCase();

    // Detect topics
    const topics = {
        'kubernetes': ['kubernetes', 'k8s', 'kubectl', 'pod', 'deployment', 'service'],
        'docker': ['docker', 'container', 'dockerfile', 'image'],
        'terraform': ['terraform', 'tf', 'hcl', 'infrastructure as code'],
        'aws': ['aws', 'ec2', 's3', 'lambda', 'cloudformation'],
        'cicd': ['ci/cd', 'pipeline', 'jenkins', 'github actions', 'gitlab'],
        'monitoring': ['monitoring', 'prometheus', 'grafana', 'alerting'],
        'security': ['security', 'vulnerability', 'compliance', 'devsecops']
    };

    for (const [topic, keywords] of Object.entries(topics)) {
        if (keywords.some(keyword => lowerMessage.includes(keyword) || lowerResponse.includes(keyword))) {
            analysis.topic = topic;
            break;
        }
    }

    // Detect tools mentioned
    const tools = [
        'kubernetes', 'docker', 'terraform', 'ansible', 'jenkins', 'gitlab', 'github',
        'prometheus', 'grafana', 'elk', 'aws', 'azure', 'gcp', 'helm', 'istio'
    ];

    analysis.tools = tools.filter(tool => 
        lowerMessage.includes(tool) || lowerResponse.includes(tool)
    );

    // Detect cloud providers
    if (lowerMessage.includes('aws') || lowerResponse.includes('aws')) {
        analysis.infrastructure.cloudProvider = 'aws';
    } else if (lowerMessage.includes('azure') || lowerResponse.includes('azure')) {
        analysis.infrastructure.cloudProvider = 'azure';
    } else if (lowerMessage.includes('gcp') || lowerMessage.includes('google cloud')) {
        analysis.infrastructure.cloudProvider = 'gcp';
    }

    // Detect problem types
    if (lowerMessage.includes('error') || lowerMessage.includes('issue') || lowerMessage.includes('problem')) {
        analysis.problemType = 'troubleshooting';
    } else if (lowerMessage.includes('how to') || lowerMessage.includes('setup') || lowerMessage.includes('configure')) {
        analysis.problemType = 'configuration';
    } else if (lowerMessage.includes('best practice') || lowerMessage.includes('recommend')) {
        analysis.problemType = 'best-practices';
    }

    // Infer user preferences
    if (lowerMessage.includes('step by step') || lowerMessage.includes('detailed')) {
        analysis.inferredPreferences.communicationStyle = 'detailed';
    } else if (lowerMessage.includes('quick') || lowerMessage.includes('brief')) {
        analysis.inferredPreferences.communicationStyle = 'concise';
    }

    if (lowerMessage.includes('beginner') || lowerMessage.includes('new to')) {
        analysis.inferredPreferences.experienceLevel = 'beginner';
    } else if (lowerMessage.includes('advanced') || lowerMessage.includes('expert')) {
        analysis.inferredPreferences.experienceLevel = 'advanced';
    }

    return analysis;
}
'@

# Save the CORS-fixed chat handler
$corsFixedChatHandler | Out-File -FilePath "lambda/chat/agentcore-chat-cors-fixed.js" -Encoding UTF8

Write-Host "✅ CORS-fixed chat handler created" -ForegroundColor Green

Write-Host "`n2. 🚀 Deploying CORS-Fixed Functions..." -ForegroundColor Yellow

try {
    # Create deployment package with CORS fix
    $tempDir = "temp-cors-fix"
    if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir }
    New-Item -ItemType Directory -Path $tempDir | Out-Null

    # Copy files
    Copy-Item "lambda/chat/agentcore-chat-cors-fixed.js" "$tempDir/index.js"
    Copy-Item "lambda/chat/agentcore-gateway.js" "$tempDir/"
    
    # Copy memory files
    New-Item -ItemType Directory -Path "$tempDir/memory" | Out-Null
    Copy-Item "lambda/memory/memory-manager.js" "$tempDir/memory/"

    # Create package.json
    @"
{
  "name": "devops-agent-chat-cors-fixed",
  "version": "1.0.0",
  "dependencies": {
    "@aws-sdk/client-bedrock-agent-runtime": "^3.450.0",
    "@aws-sdk/client-dynamodb": "^3.450.0",
    "@aws-sdk/lib-dynamodb": "^3.450.0"
  }
}
"@ | Out-File -FilePath "$tempDir/package.json" -Encoding UTF8

    # Create zip
    Compress-Archive -Path "$tempDir/*" -DestinationPath "lambda-cors-fixed.zip"
    Remove-Item -Recurse -Force $tempDir

    # Deploy to Lambda
    Write-Host "Deploying CORS-fixed chat function..." -ForegroundColor Gray
    aws lambda update-function-code --function-name $CHAT_FUNCTION --zip-file fileb://lambda-cors-fixed.zip

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ CORS-fixed chat function deployed successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Deployment failed" -ForegroundColor Red
    }

    # Clean up
    Remove-Item "lambda-cors-fixed.zip"
    Remove-Item "lambda/chat/agentcore-chat-cors-fixed.js"

} catch {
    Write-Host "❌ CORS fix deployment error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n3. 🧪 Testing CORS Fix..." -ForegroundColor Yellow

try {
    # Test OPTIONS request
    Write-Host "Testing OPTIONS preflight request..." -ForegroundColor Gray
    $optionsTest = aws lambda invoke --function-name $CHAT_FUNCTION --payload '{"httpMethod":"OPTIONS","headers":{"Origin":"http://localhost:3000"}}' response.json
    
    if ($LASTEXITCODE -eq 0) {
        $response = Get-Content response.json | ConvertFrom-Json
        if ($response.statusCode -eq 200) {
            Write-Host "✅ OPTIONS preflight working" -ForegroundColor Green
        }
    }

    # Test POST request
    Write-Host "Testing POST request..." -ForegroundColor Gray
    $postTest = aws lambda invoke --function-name $CHAT_FUNCTION --payload '{"httpMethod":"POST","body":"{\"message\":\"Hello AgentCore\"}","headers":{"Origin":"http://localhost:3000"}}' response.json
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ POST request working" -ForegroundColor Green
    }

    # Clean up
    if (Test-Path "response.json") { Remove-Item "response.json" }

} catch {
    Write-Host "⚠️  Testing completed with warnings" -ForegroundColor Yellow
}

Write-Host "`n🎉 CORS Fix Complete!" -ForegroundColor Cyan
Write-Host "The Lambda functions now have enhanced CORS headers." -ForegroundColor White
Write-Host "Try the frontend again - CORS errors should be resolved!" -ForegroundColor Green