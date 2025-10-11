/**
 * Demo data and utilities for the DevOps KnowledgeOps Agent
 */

export interface DemoScenario {
  id: string;
  title: string;
  description: string;
  userQuery: string;
  expectedResponse: string;
  context?: any;
}

export const DEMO_SCENARIOS: DemoScenario[] = [
  {
    id: 'eks-troubleshooting',
    title: 'EKS Cluster Troubleshooting',
    description: 'Help with Kubernetes cluster issues on AWS EKS',
    userQuery: 'My EKS cluster pods are failing to start with ImagePullBackOff errors. How do I troubleshoot this?',
    expectedResponse: 'ImagePullBackOff errors in EKS typically indicate issues with container image access...',
    context: {
      cloudProvider: 'aws',
      environment: 'prod',
      tools: ['kubernetes', 'eks', 'docker']
    }
  },
  {
    id: 'terraform-best-practices',
    title: 'Terraform Infrastructure Setup',
    description: 'Best practices for Infrastructure as Code with Terraform',
    userQuery: 'What are the best practices for organizing Terraform code for a multi-environment AWS setup?',
    expectedResponse: 'For multi-environment Terraform setups, I recommend following these best practices...',
    context: {
      cloudProvider: 'aws',
      tools: ['terraform', 'iac']
    }
  },
  {
    id: 'cicd-pipeline-design',
    title: 'CI/CD Pipeline Design',
    description: 'Designing efficient CI/CD pipelines',
    userQuery: 'How should I design a CI/CD pipeline for a microservices application using GitHub Actions and AWS?',
    expectedResponse: 'For microservices CI/CD with GitHub Actions and AWS, consider this architecture...',
    context: {
      cloudProvider: 'aws',
      tools: ['github', 'cicd', 'microservices']
    }
  },
  {
    id: 'monitoring-setup',
    title: 'Monitoring and Observability',
    description: 'Setting up comprehensive monitoring',
    userQuery: 'What monitoring stack would you recommend for a containerized application running on EKS?',
    expectedResponse: 'For EKS monitoring, I recommend a comprehensive observability stack including...',
    context: {
      cloudProvider: 'aws',
      tools: ['kubernetes', 'eks', 'monitoring', 'prometheus', 'grafana']
    }
  },
  {
    id: 'security-hardening',
    title: 'Security Hardening',
    description: 'DevSecOps and security best practices',
    userQuery: 'How can I implement security scanning and compliance checks in my DevOps pipeline?',
    expectedResponse: 'Implementing DevSecOps requires integrating security at every stage...',
    context: {
      tools: ['security', 'devsecops', 'compliance']
    }
  }
];

export const DEMO_RESPONSES = {
  'welcome': `👋 Welcome to the DevOps KnowledgeOps Agent! 

I'm your AI-powered DevOps expert, built with Amazon Bedrock AgentCore and enhanced with Strands reasoning capabilities. I can help you with:

🔧 **Infrastructure & Cloud**: AWS, Azure, GCP, hybrid setups
🚀 **CI/CD Pipelines**: GitHub Actions, Jenkins, GitLab CI, AWS CodePipeline  
📦 **Containers**: Docker, Kubernetes, EKS, container orchestration
📊 **Monitoring**: Prometheus, Grafana, CloudWatch, observability
🔒 **Security**: DevSecOps practices, compliance, vulnerability management
⚡ **Automation**: Terraform, Ansible, Infrastructure as Code
🐛 **Troubleshooting**: System debugging, performance optimization

Try asking me about any DevOps challenge you're facing!`,

  'capabilities': `🚀 **My Capabilities**

**Advanced AI Reasoning**: Powered by Bedrock AgentCore with Strands integration for multi-step problem solving

**Comprehensive Knowledge**: 
- Infrastructure as Code (Terraform, CloudFormation, Pulumi)
- Container orchestration (Docker, Kubernetes, EKS, ECS)
- CI/CD pipelines and automation
- Monitoring and observability
- Security and compliance (DevSecOps)
- Multi-cloud and hybrid environments

**Interactive Features**:
- Context-aware conversations with memory
- Code generation and validation
- Step-by-step troubleshooting guides
- Best practice recommendations
- Real-time AWS service integration

**Demo Scenarios**: Try these example queries:
- "Help me troubleshoot EKS pod failures"
- "Design a CI/CD pipeline for microservices"
- "What's the best monitoring setup for containers?"
- "How do I implement security scanning in my pipeline?"`,

  'error': `❌ I encountered an issue processing your request. This might be due to:

- Temporary service unavailability
- Network connectivity issues
- Invalid request format

Please try again, or rephrase your question. If the issue persists, you can:
1. Check your network connection
2. Try a simpler query first
3. Contact support if needed

I'm here to help with your DevOps challenges! 🛠️`
};

export function getRandomDemoScenario(): DemoScenario {
  return DEMO_SCENARIOS[Math.floor(Math.random() * DEMO_SCENARIOS.length)];
}

export function getDemoResponse(key: keyof typeof DEMO_RESPONSES): string {
  return DEMO_RESPONSES[key];
}