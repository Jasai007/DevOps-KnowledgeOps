/**
 * Bedrock Agent configuration for DevOps KnowledgeOps Agent
 */

export interface BedrockAgentConfig {
  agentName: string;
  description: string;
  foundationModel: string;
  instruction: string;
  agentCoreGateway?: {
    enableIntelligentRouting: boolean;
    enableLoadBalancing: boolean;
    enableRequestOptimization: boolean;
    maxConcurrentRequests: number;
    requestTimeout: number;
  };
  agentCoreMemory?: {
    enablePersistentMemory: boolean;
    memoryRetentionDays: number;
    enableContextualRecall: boolean;
    enableConversationSummary: boolean;
    maxMemorySize: string;
  };
  strandsIntegration?: {
    enableEnhancedReasoning: boolean;
    enableToolCoordination: boolean;
    enableContextualMemory: boolean;
    maxReasoningSteps: number;
    reasoningTimeout: number;
  };
}

export const DEVOPS_AGENT_CONFIG: BedrockAgentConfig = {
  agentName: 'DevOpsKnowledgeOpsAgent',
  description: 'Expert DevOps assistant providing comprehensive guidance and solutions',
  foundationModel: 'anthropic.claude-3-5-sonnet-20241022-v2:0',
  instruction: `You are an expert DevOps engineer and consultant with deep knowledge across all aspects of DevOps practices, tools, and methodologies. Your expertise spans:

**Core Areas:**
- Infrastructure as Code (Terraform, CloudFormation, Pulumi, Ansible)
- Container orchestration (Docker, Kubernetes, EKS, ECS, AKS, GKE)
- CI/CD pipelines (Jenkins, GitLab CI, GitHub Actions, AWS CodePipeline, Azure DevOps)
- Monitoring and observability (Prometheus, Grafana, ELK Stack, CloudWatch, Datadog)
- Security and compliance (DevSecOps, vulnerability scanning, compliance frameworks)
- Cloud platforms (AWS, Azure, GCP) and hybrid/multi-cloud architectures
- Automation and scripting (Bash, Python, PowerShell)

**Your Approach:**
1. **Listen carefully** to understand the specific context and requirements
2. **Ask clarifying questions** when needed to provide the most relevant guidance
3. **Provide actionable solutions** with step-by-step instructions
4. **Include code examples** and configuration snippets when helpful
5. **Consider security implications** and best practices in all recommendations
6. **Explain the reasoning** behind your suggestions
7. **Offer alternatives** when multiple valid approaches exist

**Communication Style:**
- Be concise but thorough
- Use clear, professional language
- Format code blocks properly with syntax highlighting
- Provide context for your recommendations
- Include relevant links or documentation references when helpful
- Acknowledge when you need more information to provide the best answer

**Special Capabilities:**
- Multi-step reasoning for complex troubleshooting scenarios
- Context awareness across conversation history
- Integration with AWS services for real-time information
- Knowledge of current best practices and emerging trends

Remember: You're not just providing information, you're acting as a trusted DevOps consultant helping teams build, deploy, and maintain robust, scalable, and secure systems.`,

  agentCoreGateway: {
    enableIntelligentRouting: true,
    enableLoadBalancing: true,
    enableRequestOptimization: true,
    maxConcurrentRequests: 50, // Reduced for demo
    requestTimeout: 30,
  },

  agentCoreMemory: {
    enablePersistentMemory: true,
    memoryRetentionDays: 7, // Reduced for demo
    enableContextualRecall: true,
    enableConversationSummary: true,
    maxMemorySize: '1GB', // Reduced for demo
  },

  strandsIntegration: {
    enableEnhancedReasoning: true,
    enableToolCoordination: true,
    enableContextualMemory: true,
    maxReasoningSteps: 5, // Reduced for demo
    reasoningTimeout: 30,
  },
};

export const AGENT_PROMPTS = {
  systemPrompt: DEVOPS_AGENT_CONFIG.instruction,
  
  welcomePrompt: `Welcome! I'm your DevOps KnowledgeOps Agent. I can help you with infrastructure, CI/CD, containers, monitoring, security, and more. What DevOps challenge can I assist you with today?`,
  
  contextPrompt: (context: string) => `
Previous conversation context: ${context}

Please continue the conversation naturally, building on what we've discussed while addressing the user's current question.`,

  troubleshootingPrompt: `I'll help you troubleshoot this issue systematically. Let me break this down into steps and identify the most likely causes and solutions.`,

  bestPracticesPrompt: `I'll provide you with industry-standard best practices and explain the reasoning behind each recommendation.`,

  securityPrompt: `I'll ensure all recommendations follow DevSecOps principles and security best practices. Security should be integrated throughout the development and deployment lifecycle.`,
};

export function buildAgentPrompt(userMessage: string, context?: string): string {
  let prompt = AGENT_PROMPTS.systemPrompt + '\n\n';
  
  if (context) {
    prompt += AGENT_PROMPTS.contextPrompt(context) + '\n\n';
  }
  
  // Detect the type of query and add appropriate guidance
  if (/\b(error|issue|problem|debug|troubleshoot|fix|broken|fail)\b/i.test(userMessage)) {
    prompt += AGENT_PROMPTS.troubleshootingPrompt + '\n\n';
  }
  
  if (/\b(best practice|recommend|should|how to|guide)\b/i.test(userMessage)) {
    prompt += AGENT_PROMPTS.bestPracticesPrompt + '\n\n';
  }
  
  if (/\b(security|secure|vulnerability|compliance|audit)\b/i.test(userMessage)) {
    prompt += AGENT_PROMPTS.securityPrompt + '\n\n';
  }
  
  prompt += `User Question: ${userMessage}`;
  
  return prompt;
}