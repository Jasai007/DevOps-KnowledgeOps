import {
  BedrockAgentClient,
  CreateAgentCommand,
  PrepareAgentCommand,
} from '@aws-sdk/client-bedrock-agent';
import {
  BedrockAgentRuntimeClient,
  InvokeAgentCommand,
  InvokeAgentCommandInput,
} from '@aws-sdk/client-bedrock-agent-runtime';
import { DEVOPS_AGENT_CONFIG } from './agent-config';
import { S3VectorStore, S3VectorStoreConfig } from './s3-vector-store';

export interface AgentResponse {
  success: boolean;
  response?: string;
  sessionId?: string;
  error?: string;
  metadata?: {
    responseTime: number;
    tokensUsed?: number;
    confidence?: number;
  };
}

export class BedrockAgentManager {
  private agentClient: BedrockAgentClient;
  private runtimeClient: BedrockAgentRuntimeClient;
  private vectorStore: S3VectorStore;
  private agentId?: string;
  private agentAliasId?: string;

  constructor(region: string = 'us-east-1') {
    this.agentClient = new BedrockAgentClient({ region });
    this.runtimeClient = new BedrockAgentRuntimeClient({ region });

    // Initialize S3 Vector Store
    const vectorConfig: S3VectorStoreConfig = {
      bucketName: process.env.KNOWLEDGE_BUCKET_NAME || 'devops-knowledge-992382848863-us-east-1',
      vectorPrefix: 'vectors/',
      documentsPrefix: 'knowledge-base/',
      indexPrefix: 'index/',
      embeddingModel: process.env.EMBEDDING_MODEL || 'amazon.titan-embed-text-v2:0',
      dimensions: parseInt(process.env.VECTOR_DIMENSIONS || '1024'),
      region
    };

    this.vectorStore = new S3VectorStore(vectorConfig);

    // Get agent ID from environment or use default
    this.agentId = process.env.BEDROCK_AGENT_ID || 'MNJESZYALW';
    this.agentAliasId = process.env.BEDROCK_AGENT_ALIAS_ID || 'TSTALIASID';

    console.log(`Bedrock Agent Manager initialized with Agent ID: ${this.agentId}`);
    console.log(`S3 Vector Store configured with bucket: ${vectorConfig.bucketName}`);
  }

  async createAgent(): Promise<string | null> {
    try {
      const command = new CreateAgentCommand({
        agentName: DEVOPS_AGENT_CONFIG.agentName,
        description: DEVOPS_AGENT_CONFIG.description,
        foundationModel: DEVOPS_AGENT_CONFIG.foundationModel,
        instruction: DEVOPS_AGENT_CONFIG.instruction,
        agentResourceRoleArn: process.env.AGENT_ROLE_ARN || '',
        // Note: AgentCore specific configurations would be set through AWS Console or separate APIs
      });

      const response = await this.agentClient.send(command);
      this.agentId = response.agent?.agentId;

      if (this.agentId) {
        // Prepare the agent
        await this.prepareAgent();
        return this.agentId;
      }

      return null;
    } catch (error) {
      console.error('Error creating agent:', error);
      return null;
    }
  }

  async prepareAgent(): Promise<boolean> {
    if (!this.agentId) {
      console.error('No agent ID available');
      return false;
    }

    try {
      const command = new PrepareAgentCommand({
        agentId: this.agentId,
      });

      await this.agentClient.send(command);
      return true;
    } catch (error) {
      console.error('Error preparing agent:', error);
      return false;
    }
  }

  async invokeAgent(
    userMessage: string,
    sessionId: string,
    _context?: string
  ): Promise<AgentResponse> {
    const startTime = Date.now();

    try {
      if (!this.agentId) {
        // Use mock response if agent isn't configured
        return this.getMockResponse(userMessage, sessionId, startTime);
      }

      console.log(`Invoking Bedrock Agent: ${this.agentId} with alias: ${this.agentAliasId}`);

      const input: InvokeAgentCommandInput = {
        agentId: this.agentId,
        agentAliasId: this.agentAliasId,
        sessionId: sessionId,
        inputText: userMessage,
      };

      const command = new InvokeAgentCommand(input);
      const response = await this.runtimeClient.send(command);

      // Process the streaming response
      let fullResponse = '';
      if (response.completion) {
        for await (const chunk of response.completion) {
          if (chunk.chunk?.bytes) {
            const text = Buffer.from(chunk.chunk.bytes).toString('utf-8');
            fullResponse += text;
          }
        }
      }

      const responseTime = Date.now() - startTime;

      return {
        success: true,
        response: fullResponse || 'I apologize, but I didn\'t receive a complete response. Please try again.',
        sessionId: sessionId,
        metadata: {
          responseTime,
          confidence: 0.9,
        },
      };

    } catch (error: any) {
      console.error('Error invoking agent:', error);

      const responseTime = Date.now() - startTime;

      // Fallback to mock response on error
      const mockResponse = this.getMockResponse(userMessage, sessionId, startTime);
      mockResponse.error = `Agent error (falling back to demo): ${error.message}`;

      return mockResponse;
    }
  }



  private getMockResponse(userMessage: string, sessionId: string, startTime: number): AgentResponse {
    // Mock responses for demo purposes when agent isn't fully configured
    const mockResponses = {
      greeting: `Hello! I'm the DevOps KnowledgeOps Agent, powered by Amazon Bedrock AgentCore. I'm here to help you with all your DevOps challenges!

I can assist you with:
🔧 Infrastructure as Code (Terraform, CloudFormation)
🚀 CI/CD Pipelines (Jenkins, GitHub Actions, AWS CodePipeline)
📦 Container Orchestration (Docker, Kubernetes, EKS)
📊 Monitoring & Observability (Prometheus, Grafana, CloudWatch)
🔒 Security & Compliance (DevSecOps practices)
☁️ Multi-cloud & Hybrid Architectures

What DevOps challenge can I help you solve today?`,

      kubernetes: `For Kubernetes troubleshooting, I recommend following this systematic approach:

1. **Check Pod Status**:
   \`\`\`bash
   kubectl get pods -n <namespace>
   kubectl describe pod <pod-name> -n <namespace>
   \`\`\`

2. **Examine Logs**:
   \`\`\`bash
   kubectl logs <pod-name> -n <namespace> --previous
   \`\`\`

3. **Check Resource Constraints**:
   \`\`\`bash
   kubectl top pods -n <namespace>
   kubectl describe nodes
   \`\`\`

4. **Verify Network Connectivity**:
   \`\`\`bash
   kubectl get svc -n <namespace>
   kubectl get endpoints -n <namespace>
   \`\`\`

Would you like me to dive deeper into any specific aspect of your Kubernetes issue?`,

      terraform: `Here are Terraform best practices for multi-environment setups:

## 1. Directory Structure
\`\`\`
terraform/
├── environments/
│   ├── dev/
│   ├── staging/
│   └── prod/
├── modules/
│   ├── vpc/
│   ├── eks/
│   └── rds/
└── shared/
\`\`\`

## 2. Use Workspaces or Separate State Files
\`\`\`bash
# Option 1: Workspaces
terraform workspace new dev
terraform workspace select dev

# Option 2: Separate backends
terraform init -backend-config="key=dev/terraform.tfstate"
\`\`\`

## 3. Variable Management
\`\`\`hcl
# terraform.tfvars.example
environment = "dev"
instance_type = "t3.micro"
min_size = 1
max_size = 3
\`\`\`

## 4. Remote State Management
\`\`\`hcl
terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "environments/dev/terraform.tfstate"
    region = "us-east-1"
  }
}
\`\`\`

Would you like me to elaborate on any of these practices?`,

      cicd: `For a microservices CI/CD pipeline with GitHub Actions and AWS, here's a recommended architecture:

## Pipeline Structure

### 1. Repository Setup
\`\`\`yaml
# .github/workflows/deploy.yml
name: Deploy Microservice
on:
  push:
    branches: [main]
    paths: ['services/user-service/**']

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: \${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: \${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
\`\`\`

### 2. Build Stage
\`\`\`yaml
      - name: Build and push Docker image
        run: |
          docker build -t \$ECR_REGISTRY/user-service:\$GITHUB_SHA .
          docker push \$ECR_REGISTRY/user-service:\$GITHUB_SHA
\`\`\`

### 3. Deploy Stage
\`\`\`yaml
      - name: Deploy to EKS
        run: |
          aws eks update-kubeconfig --name production-cluster
          kubectl set image deployment/user-service user-service=\$ECR_REGISTRY/user-service:\$GITHUB_SHA
\`\`\`

### 4. Key Components:
- **ECR** for container registry
- **EKS** for orchestration
- **ALB** for load balancing
- **Route53** for DNS
- **CloudWatch** for monitoring

Would you like me to detail any specific part of this pipeline?`,

      monitoring: `For EKS monitoring, I recommend this comprehensive observability stack:

## Core Components

### 1. Metrics Collection
\`\`\`yaml
# Prometheus configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    scrape_configs:
      - job_name: 'kubernetes-pods'
        kubernetes_sd_configs:
          - role: pod
\`\`\`

### 2. Visualization
- **Grafana** for dashboards
- **Pre-built dashboards** for Kubernetes metrics
- **Custom dashboards** for application metrics

### 3. Logging
\`\`\`yaml
# Fluent Bit DaemonSet
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluent-bit
spec:
  template:
    spec:
      containers:
      - name: fluent-bit
        image: fluent/fluent-bit:latest
\`\`\`

### 4. Alerting
\`\`\`yaml
# AlertManager rules
groups:
- name: kubernetes
  rules:
  - alert: PodCrashLooping
    expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
    for: 5m
\`\`\`

### 5. AWS Integration
- **CloudWatch Container Insights**
- **AWS X-Ray** for distributed tracing
- **AWS CloudTrail** for audit logs

Would you like me to provide specific configuration examples for any of these components?`,

      security: `Implementing DevSecOps requires integrating security at every stage of your pipeline:

## 1. Source Code Security

### Static Analysis
\`\`\`yaml
# GitHub Actions security scanning
- name: Run security scan
  uses: github/super-linter@v4
  env:
    DEFAULT_BRANCH: main
    GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
\`\`\`

### Dependency Scanning
\`\`\`yaml
- name: Run Snyk to check for vulnerabilities
  uses: snyk/actions/node@master
  env:
    SNYK_TOKEN: \${{ secrets.SNYK_TOKEN }}
\`\`\`

## 2. Container Security

### Image Scanning
\`\`\`bash
# Trivy container scanning
trivy image --severity HIGH,CRITICAL myapp:latest
\`\`\`

### Runtime Security
\`\`\`yaml
# Falco for runtime monitoring
apiVersion: v1
kind: ConfigMap
metadata:
  name: falco-config
data:
  falco.yaml: |
    rules_file:
      - /etc/falco/falco_rules.yaml
\`\`\`

## 3. Infrastructure Security

### Policy as Code
\`\`\`hcl
# OPA/Gatekeeper policies
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: k8srequiredsecuritycontext
\`\`\`

### Compliance Scanning
\`\`\`bash
# CIS Kubernetes Benchmark
kube-bench run --targets node,policies,managedservices
\`\`\`

## 4. Secrets Management
- **AWS Secrets Manager** or **HashiCorp Vault**
- **External Secrets Operator** for Kubernetes
- **Sealed Secrets** for GitOps workflows

Would you like me to dive deeper into any specific security aspect?`,

      default: `I understand you're looking for DevOps guidance. As your AI-powered DevOps expert with Bedrock AgentCore, I can help you with:

**Infrastructure & Automation:**
- Infrastructure as Code (Terraform, CloudFormation, Pulumi)
- Configuration management (Ansible, Chef, Puppet)
- Cloud architecture (AWS, Azure, GCP, hybrid)

**CI/CD & Development:**
- Pipeline design and optimization
- GitOps workflows
- Automated testing strategies
- Deployment patterns (blue-green, canary, rolling)

**Containers & Orchestration:**
- Docker containerization
- Kubernetes cluster management
- Service mesh (Istio, Linkerd)
- Container security

**Monitoring & Operations:**
- Observability stack setup
- SRE practices
- Incident response
- Performance optimization

**Security & Compliance:**
- DevSecOps implementation
- Vulnerability management
- Compliance automation
- Zero-trust architecture

Could you please provide more specific details about your DevOps challenge? The more context you give me, the better I can tailor my recommendations to your specific situation.`
    };

    // Simple keyword matching for demo responses
    const message = userMessage.toLowerCase();
    let response = mockResponses.default;

    if (message.includes('hello') || message.includes('hi') || message.includes('welcome')) {
      response = mockResponses.greeting;
    } else if (message.includes('kubernetes') || message.includes('k8s') || message.includes('pod')) {
      response = mockResponses.kubernetes;
    } else if (message.includes('terraform') || message.includes('infrastructure')) {
      response = mockResponses.terraform;
    } else if (message.includes('cicd') || message.includes('pipeline') || message.includes('github actions')) {
      response = mockResponses.cicd;
    } else if (message.includes('monitoring') || message.includes('prometheus') || message.includes('grafana')) {
      response = mockResponses.monitoring;
    } else if (message.includes('security') || message.includes('devsecops') || message.includes('compliance')) {
      response = mockResponses.security;
    }

    const responseTime = Date.now() - startTime;

    return {
      success: true,
      response: response,
      sessionId: sessionId,
      metadata: {
        responseTime,
        confidence: 0.95,
      },
    };
  }
}