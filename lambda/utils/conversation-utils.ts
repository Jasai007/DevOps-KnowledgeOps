import { SessionManager, ChatMessage } from '../session/session-manager';

export interface ConversationContext extends Record<string, unknown> {
  currentTopic?: string;
  mentionedTools?: string[];
  infrastructureContext?: {
    cloudProvider?: 'aws' | 'azure' | 'gcp' | 'hybrid';
    services?: string[];
    environment?: 'dev' | 'staging' | 'prod';
  };
  previousRecommendations?: string[];
  userPreferences?: {
    preferredTools?: string[];
    experienceLevel?: 'beginner' | 'intermediate' | 'advanced';
  };
}

export class ConversationUtils {
  private sessionManager: SessionManager;

  constructor() {
    this.sessionManager = new SessionManager();
  }

  /**
   * Extract DevOps context from user message
   */
  extractDevOpsContext(message: string): Partial<ConversationContext> {
    const context: Partial<ConversationContext> = {};
    
    // Detect cloud providers
    const cloudProviders = {
      aws: /\b(aws|amazon|ec2|s3|lambda|cloudformation|eks|ecs)\b/i,
      azure: /\b(azure|microsoft|vm|blob|functions|arm|aks|aci)\b/i,
      gcp: /\b(gcp|google|compute|storage|functions|deployment|gke)\b/i,
    };

    for (const [provider, regex] of Object.entries(cloudProviders)) {
      if (regex.test(message)) {
        context.infrastructureContext = {
          ...context.infrastructureContext,
          cloudProvider: provider as any,
        };
        break;
      }
    }

    // Detect mentioned tools
    const devopsTools = [
      'docker', 'kubernetes', 'k8s', 'terraform', 'ansible', 'jenkins', 
      'gitlab', 'github', 'circleci', 'prometheus', 'grafana', 'elk',
      'nginx', 'apache', 'redis', 'mongodb', 'postgresql', 'mysql',
      'helm', 'istio', 'vault', 'consul', 'nomad'
    ];

    const mentionedTools = devopsTools.filter(tool => 
      new RegExp(`\\b${tool}\\b`, 'i').test(message)
    );

    if (mentionedTools.length > 0) {
      context.mentionedTools = mentionedTools;
    }

    // Detect environment context
    const environments = {
      dev: /\b(dev|development|local)\b/i,
      staging: /\b(staging|stage|test|testing)\b/i,
      prod: /\b(prod|production|live)\b/i,
    };

    for (const [env, regex] of Object.entries(environments)) {
      if (regex.test(message)) {
        context.infrastructureContext = {
          ...context.infrastructureContext,
          environment: env as any,
        };
        break;
      }
    }

    // Detect topics
    const topics = {
      'ci/cd': /\b(ci\/cd|pipeline|build|deploy|deployment|continuous)\b/i,
      'monitoring': /\b(monitor|observability|metrics|logs|alerts|dashboard)\b/i,
      'security': /\b(security|vulnerability|compliance|audit|encryption)\b/i,
      'infrastructure': /\b(infrastructure|iac|provisioning|scaling|architecture)\b/i,
      'containers': /\b(container|docker|kubernetes|orchestration|microservices)\b/i,
      'troubleshooting': /\b(error|issue|problem|debug|troubleshoot|fix)\b/i,
    };

    for (const [topic, regex] of Object.entries(topics)) {
      if (regex.test(message)) {
        context.currentTopic = topic;
        break;
      }
    }

    return context;
  }

  /**
   * Build conversation context from message history
   */
  async buildConversationContext(sessionId: string): Promise<ConversationContext> {
    const messages = await this.sessionManager.getSessionMessages(sessionId, 20);
    const context: ConversationContext = {
      mentionedTools: [],
      previousRecommendations: [],
    };

    // Analyze recent messages for context
    for (const message of messages) {
      const messageContext = this.extractDevOpsContext(message.content);
      
      // Merge mentioned tools
      if (messageContext.mentionedTools) {
        context.mentionedTools = [
          ...new Set([...(context.mentionedTools || []), ...messageContext.mentionedTools])
        ];
      }

      // Update current topic (latest wins)
      if (messageContext.currentTopic) {
        context.currentTopic = messageContext.currentTopic;
      }

      // Update infrastructure context (latest wins)
      if (messageContext.infrastructureContext) {
        context.infrastructureContext = {
          ...context.infrastructureContext,
          ...messageContext.infrastructureContext,
        };
      }

      // Collect recommendations from assistant messages
      if (message.role === 'assistant' && message.content.includes('recommend')) {
        context.previousRecommendations?.push(
          message.content.substring(0, 100) + '...'
        );
      }
    }

    return context;
  }

  /**
   * Format conversation history for AI context
   */
  formatConversationHistory(messages: ChatMessage[]): string {
    if (messages.length === 0) {
      return 'This is the start of a new conversation.';
    }

    const recentMessages = messages.slice(-10); // Last 10 messages
    const formatted = recentMessages.map(msg => 
      `${msg.role === 'user' ? 'User' : 'Assistant'}: ${msg.content}`
    ).join('\n\n');

    return `Previous conversation:\n${formatted}`;
  }

  /**
   * Generate context summary for AI prompt
   */
  generateContextSummary(context: ConversationContext): string {
    const parts: string[] = [];

    if (context.currentTopic) {
      parts.push(`Current topic: ${context.currentTopic}`);
    }

    if (context.mentionedTools && context.mentionedTools.length > 0) {
      parts.push(`Tools discussed: ${context.mentionedTools.join(', ')}`);
    }

    if (context.infrastructureContext?.cloudProvider) {
      parts.push(`Cloud provider: ${context.infrastructureContext.cloudProvider}`);
    }

    if (context.infrastructureContext?.environment) {
      parts.push(`Environment: ${context.infrastructureContext.environment}`);
    }

    if (context.userPreferences?.experienceLevel) {
      parts.push(`User experience level: ${context.userPreferences.experienceLevel}`);
    }

    return parts.length > 0 
      ? `Context: ${parts.join(', ')}`
      : 'No specific context established yet.';
  }
}