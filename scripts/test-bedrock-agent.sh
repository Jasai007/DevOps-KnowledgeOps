#!/bin/bash

set -e

echo "🧪 Testing Bedrock Agent..."

# Load configuration if available
if [ -f "bedrock-config.env" ]; then
    source bedrock-config.env
    echo "✅ Loaded configuration from bedrock-config.env"
fi

# Check required environment variables
if [ -z "$BEDROCK_AGENT_ID" ]; then
    echo "❌ BEDROCK_AGENT_ID not set. Please run setup-bedrock-agent.sh first."
    exit 1
fi

if [ -z "$BEDROCK_AGENT_ALIAS_ID" ]; then
    echo "❌ BEDROCK_AGENT_ALIAS_ID not set. Please run setup-bedrock-agent.sh first."
    exit 1
fi

REGION=${AWS_REGION:-us-east-1}
SESSION_ID="test-session-$(date +%s)"

echo "🔧 Configuration:"
echo "Agent ID: $BEDROCK_AGENT_ID"
echo "Alias ID: $BEDROCK_AGENT_ALIAS_ID"
echo "Region: $REGION"
echo "Session ID: $SESSION_ID"
echo ""

# Test queries
declare -a test_queries=(
    "Hello, can you help me with DevOps?"
    "What are the best practices for Kubernetes deployment?"
    "How do I troubleshoot EKS cluster issues?"
    "Design a CI/CD pipeline for microservices"
    "What monitoring tools do you recommend for containerized applications?"
)

echo "🚀 Running test queries..."
echo ""

for i in "${!test_queries[@]}"; do
    query="${test_queries[$i]}"
    echo "📝 Test $((i+1)): $query"
    echo "----------------------------------------"
    
    # Invoke the agent
    response=$(aws bedrock-agent-runtime invoke-agent \
        --agent-id "$BEDROCK_AGENT_ID" \
        --agent-alias-id "$BEDROCK_AGENT_ALIAS_ID" \
        --session-id "$SESSION_ID" \
        --input-text "$query" \
        --region "$REGION" \
        --output json 2>/dev/null || echo '{"completion": [{"chunk": {"bytes": "RXJyb3I6IEZhaWxlZCB0byBpbnZva2UgYWdlbnQ="}}]}')
    
    # Extract and decode the response
    if echo "$response" | jq -e '.completion' > /dev/null 2>&1; then
        # Extract bytes and decode
        bytes=$(echo "$response" | jq -r '.completion[0].chunk.bytes // empty')
        if [ -n "$bytes" ]; then
            decoded_response=$(echo "$bytes" | base64 -d 2>/dev/null || echo "Failed to decode response")
            echo "🤖 Response: $decoded_response"
        else
            echo "⚠️  No response received"
        fi
    else
        echo "❌ Failed to invoke agent"
        echo "Response: $response"
    fi
    
    echo ""
    echo "----------------------------------------"
    echo ""
    
    # Wait between requests
    sleep 2
done

echo "✅ Agent testing completed!"
echo ""
echo "💡 If you see proper responses, your Bedrock Agent is working correctly!"
echo "💡 If you see errors, check:"
echo "   - Model access permissions in Bedrock console"
echo "   - Agent preparation status"
echo "   - IAM role permissions"
echo "   - Knowledge base ingestion status"