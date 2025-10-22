/**
 * API service for DevOps KnowledgeOps Agent
 */

// Update API_BASE_URL to use Amplify backend or Elastic Beanstalk
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:3000/api';

export interface AuthRequest {
  action: 'signin' | 'signup';
  username?: string;
  password?: string;
  email?: string;
}

export interface AuthResponse {
  success: boolean;
  accessToken?: string;
  idToken?: string;
  refreshToken?: string;
  error?: string;
  message?: string;
  data?: {
    success: boolean;
    accessToken: string;
    idToken: string;
    refreshToken: string;
    user: {
      email: string;
      username: string;
      role: string;
    };
    message: string;
  };
}

export interface ChatRequest {
  message: string;
  sessionId?: string;
}

export interface ChatResponse {
  success: boolean;
  response?: string;
  sessionId?: string;
  error?: string;
  metadata?: {
    responseTime: number;
    confidence?: number;
    agentId?: string;
    region?: string;
    messageCount?: number;
    contextUsed?: boolean;
  };
}

export interface SessionRequest {
  action: 'create' | 'get' | 'list' | 'messages';
  sessionId?: string;
}

export interface Message {
  id: string;
  messageId?: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: string;
}

export interface Session {
  sessionId: string;
  createdAt: string;
  lastActivity: string;
  messageCount: number;
  preview?: string;
}

export interface SessionResponse {
  success: boolean;
  session?: Session;
  sessions?: Session[];
  messages?: Message[];
  error?: string;
  sessionId?: string;
  messageCount?: number;
  createdAt?: string;
}

class ApiService {
  private accessToken: string | null = null;

  constructor() {
    // Load Cognito token from localStorage
    this.accessToken = localStorage.getItem('accessToken');

    // No auto-authentication - users must explicitly sign in with Cognito
    console.log('API Service initialized with Cognito authentication');
  }



  private async makeRequest<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<T> {
    const url = `${API_BASE_URL}${endpoint}`;

    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      ...(options.headers as Record<string, string>),
    };

    // Use ID token for Cognito user identification
    const idToken = localStorage.getItem('idToken');
    if (idToken) {
      headers['Authorization'] = `Bearer ${idToken}`;
    } else if (this.accessToken) {
      headers['Authorization'] = `Bearer ${this.accessToken}`;
    }

    const response = await fetch(url, {
      ...options,
      headers,
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    return response.json();
  }

  // Authentication methods
  async signIn(username: string, password: string): Promise<AuthResponse> {
    try {
      // Use direct fetch to avoid makeRequest complications
      const response = await fetch(`${API_BASE_URL}/auth`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          action: 'signin',
          username: username,
          password,
        }),
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();

      // Handle the nested response structure from Lambda API
      if (data.success && data.data?.accessToken) {
        this.accessToken = data.data.accessToken;
        localStorage.setItem('accessToken', data.data.accessToken);
        if (data.data.idToken) {
          localStorage.setItem('idToken', data.data.idToken);
        }
      }

      return {
        success: data.success,
        accessToken: data.data?.accessToken,
        idToken: data.data?.idToken,
        refreshToken: data.data?.refreshToken,
        error: data.error,
        data: data.data
      };
    } catch (error) {
      console.error('Sign in error:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to sign in. Please check your connection.',
      };
    }
  }

  async signup(email: string, password: string): Promise<AuthResponse> {
    try {
      const response = await fetch(`${API_BASE_URL}/auth`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          action: 'signup',
          username: email,
          email: email,
          password: password,
        }),
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      return {
        success: data.success,
        error: data.error
      };
    } catch (error) {
      console.error('Signup error:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to sign up.',
      };
    }
  }

  // Session methods
  async createSession(): Promise<SessionResponse> {
    // Simple session creation - no storage
    const sessionId = `session-${Date.now()}`;
    return {
      success: true,
      sessionId: sessionId,
      session: {
        sessionId: sessionId,
        createdAt: new Date().toISOString(),
        lastActivity: new Date().toISOString(),
        messageCount: 0
      }
    };
  }

  async getSessionMessages(): Promise<SessionResponse> {
    // No chat history - always return empty
    return {
      success: true,
      messages: []
    };
  }

  async getUserSessions(): Promise<SessionResponse> {
    // No chat history - always return empty
    return {
      success: true,
      sessions: []
    };
  }



  // Chat methods
  async sendMessage(message: string, sessionId?: string): Promise<ChatResponse> {
    try {
      const response = await this.makeRequest<ChatResponse>('/chat', {
        method: 'POST',
        body: JSON.stringify({
          message,
          sessionId: sessionId || `session-${Date.now()}`,
        }),
      });

      return response;
    } catch (error) {
      console.error('Send message error:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to send message. Please try again.',
      };
    }
  }

  // Action methods
  async executeAction(action: string, parameters: any): Promise<any> {
    try {
      const response = await this.makeRequest('/actions', {
        method: 'POST',
        body: JSON.stringify({
          action,
          parameters,
        }),
      });

      return response;
    } catch (error) {
      console.error('Execute action error:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to execute action.',
      };
    }
  }

  // Utility methods
  isAuthenticated(): boolean {
    return !!this.accessToken;
  }

  signOut(): void {
    this.accessToken = null;
    localStorage.removeItem('accessToken');
  }

  // Set Cognito tokens (called by AuthContext after successful login)
  setCognitoToken(accessToken: string, idToken?: string): void {
    this.accessToken = accessToken;
    localStorage.setItem('accessToken', accessToken);
    if (idToken) {
      localStorage.setItem('idToken', idToken);
    }
    console.log('Cognito tokens set successfully');
  }

  // Clear authentication (for logout)
  clearAuthentication(): void {
    this.accessToken = null;
    localStorage.removeItem('accessToken');
    this.clearSessionData();
    console.log('Authentication cleared');
  }

  // Get current Cognito tokens
  getCognitoTokens(): { accessToken: string; idToken: string } | null {
    const accessToken = localStorage.getItem('accessToken');
    const idToken = localStorage.getItem('idToken');
    
    if (accessToken && idToken) {
      return { accessToken, idToken };
    }
    return null;
  }

  // Clear session data (for login/logout to prevent 403 errors)
  clearSessionData(): void {
    // Clear any cached session data that might cause 403 errors
    localStorage.removeItem('currentSessionId');
    localStorage.removeItem('chatHistory');
    console.log('Session data cleared');
  }



  // Health check method
  async checkHealth(): Promise<{ status: string; timestamp: string; config?: any; error?: string }> {
    try {
      const response = await this.makeRequest<{ status: string; timestamp: string; config?: any }>('/health');
      return response;
    } catch (error) {
      console.error('Health check error:', error);
      return {
        status: 'error',
        timestamp: new Date().toISOString(),
        error: error instanceof Error ? error.message : 'Health check failed'
      };
    }
  }

  // Connection test method
  async testConnection(): Promise<boolean> {
    try {
      const health = await this.checkHealth();
      return health.status === 'healthy';
    } catch (error) {
      console.error('Connection test failed:', error);
      return false;
    }
  }

  // Mock methods for demo purposes
  async getMockChatResponse(message: string): Promise<ChatResponse> {
    // Simulate network delay
    await new Promise(resolve => setTimeout(resolve, 1000 + Math.random() * 2000));

    const responses = this.generateMockResponses();
    const lowerMessage = message.toLowerCase();

    let response = responses.default;

    if (lowerMessage.includes('hello') || lowerMessage.includes('hi')) {
      response = responses.greeting;
    } else if (lowerMessage.includes('kubernetes') || lowerMessage.includes('k8s')) {
      response = responses.kubernetes;
    } else if (lowerMessage.includes('terraform')) {
      response = responses.terraform;
    } else if (lowerMessage.includes('cicd') || lowerMessage.includes('pipeline')) {
      response = responses.cicd;
    } else if (lowerMessage.includes('monitoring')) {
      response = responses.monitoring;
    } else if (lowerMessage.includes('security')) {
      response = responses.security;
    }

    return {
      success: true,
      response,
      sessionId: 'demo-session',
      metadata: {
        responseTime: 1500 + Math.random() * 1000,
        confidence: 0.85 + Math.random() * 0.1,
      },
    };
  }

  private generateMockResponses() {
    return {
      greeting: `Hello! I'm your DevOps KnowledgeOps Agent, powered by Amazon Bedrock AgentCore. 

I'm here to help you with all your DevOps challenges! I can assist with:

🔧 **Infrastructure**: AWS, Azure, GCP, Terraform, CloudFormation
🚀 **CI/CD**: GitHub Actions, Jenkins, GitLab CI, deployment strategies
📦 **Containers**: Docker, Kubernetes, EKS, container orchestration
📊 **Monitoring**: Prometheus, Grafana, CloudWatch, observability
🔒 **Security**: DevSecOps, vulnerability scanning, compliance
⚡ **Automation**: Infrastructure as Code, configuration management

What DevOps challenge can I help you solve today?`,

      kubernetes: `For Kubernetes troubleshooting, I'll guide you through a systematic approach:

## 🔍 **Diagnostic Steps**

### 1. Check Pod Status
\`\`\`bash
kubectl get pods -n <namespace> -o wide
kubectl describe pod <pod-name> -n <namespace>
\`\`\`

### 2. Examine Logs
\`\`\`bash
# Current logs
kubectl logs <pod-name> -n <namespace>

# Previous container logs
kubectl logs <pod-name> -n <namespace> --previous
\`\`\`

### 3. Resource Analysis
\`\`\`bash
# Check resource usage
kubectl top pods -n <namespace>
kubectl top nodes

# Check resource quotas
kubectl describe resourcequota -n <namespace>
\`\`\`

### 4. Network Diagnostics
\`\`\`bash
# Check services and endpoints
kubectl get svc,endpoints -n <namespace>

# Test DNS resolution
kubectl run debug --image=busybox -it --rm -- nslookup kubernetes.default
\`\`\`

## 🚨 **Common Issues & Solutions**

**ImagePullBackOff**: Check image name, registry access, and node permissions
**CrashLoopBackOff**: Review application logs and resource limits
**Pending Pods**: Verify node capacity and scheduling constraints

Would you like me to dive deeper into any specific Kubernetes issue you're facing?`,

      terraform: `Here's a comprehensive guide for Terraform best practices:

## 🏗️ **Project Structure**

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
    ├── backend.tf
    └── variables.tf
\`\`\`

## 🔧 **State Management**

### Remote State Configuration
\`\`\`hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state"
    key            = "env/prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
\`\`\`

### Workspace Strategy
\`\`\`bash
# Create environment workspaces
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Switch between environments
terraform workspace select prod
\`\`\`

## 📋 **Variable Management**

\`\`\`hcl
# variables.tf
variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# terraform.tfvars
environment = "prod"
instance_type = "t3.large"
\`\`\`

## 🛡️ **Security Best Practices**

- Use least privilege IAM policies
- Enable encryption for all resources
- Store secrets in AWS Secrets Manager
- Implement resource tagging strategy

Would you like me to elaborate on any specific Terraform aspect?`,

      cicd: `Here's a comprehensive CI/CD pipeline design for microservices:

## 🚀 **GitHub Actions Pipeline**

\`\`\`yaml
name: Microservice Deploy
on:
  push:
    branches: [main]
    paths: ['services/**']

jobs:
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      services: \${{ steps.changes.outputs.services }}
    steps:
      - uses: actions/checkout@v4
      - uses: dorny/paths-filter@v2
        id: changes
        with:
          filters: |
            user-service:
              - 'services/user-service/**'
            order-service:
              - 'services/order-service/**'

  build-and-deploy:
    needs: detect-changes
    if: needs.detect-changes.outputs.services != '[]'
    strategy:
      matrix:
        service: \${{ fromJSON(needs.detect-changes.outputs.services) }}
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: \${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: \${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      
      - name: Build and push Docker image
        env:
          ECR_REGISTRY: \${{ steps.login-ecr.outputs.registry }}
          SERVICE_NAME: \${{ matrix.service }}
        run: |
          cd services/\$SERVICE_NAME
          docker build -t \$ECR_REGISTRY/\$SERVICE_NAME:\$GITHUB_SHA .
          docker push \$ECR_REGISTRY/\$SERVICE_NAME:\$GITHUB_SHA
      
      - name: Deploy to EKS
        run: |
          aws eks update-kubeconfig --name production-cluster
          kubectl set image deployment/\${{ matrix.service }} \\
            \${{ matrix.service }}=\$ECR_REGISTRY/\${{ matrix.service }}:\$GITHUB_SHA
          kubectl rollout status deployment/\${{ matrix.service }}
\`\`\`

## 🏗️ **Pipeline Architecture**

**Components:**
- **Source Control**: GitHub with branch protection
- **Container Registry**: Amazon ECR
- **Orchestration**: Amazon EKS
- **Load Balancing**: AWS ALB
- **Monitoring**: CloudWatch + Prometheus

**Deployment Strategies:**
- **Blue-Green**: Zero-downtime deployments
- **Canary**: Gradual traffic shifting
- **Rolling**: Sequential pod replacement

Would you like me to detail any specific part of this pipeline architecture?`,

      monitoring: `Here's a comprehensive monitoring setup for containerized applications:

## 📊 **Observability Stack**

### Core Components
\`\`\`yaml
# Prometheus Configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      evaluation_interval: 15s
    
    rule_files:
      - "alert_rules.yml"
    
    scrape_configs:
      - job_name: 'kubernetes-pods'
        kubernetes_sd_configs:
          - role: pod
        relabel_configs:
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
            action: keep
            regex: true
\`\`\`

### Grafana Dashboards
\`\`\`yaml
# Key Metrics to Monitor
- CPU Usage: rate(cpu_usage_seconds_total[5m])
- Memory Usage: container_memory_usage_bytes / container_spec_memory_limit_bytes
- Request Rate: rate(http_requests_total[5m])
- Error Rate: rate(http_requests_total{status=~"5.."}[5m])
- Response Time: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
\`\`\`

## 🚨 **Alerting Rules**

\`\`\`yaml
groups:
- name: kubernetes-alerts
  rules:
  - alert: PodCrashLooping
    expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Pod {{ \$labels.pod }} is crash looping"
      
  - alert: HighMemoryUsage
    expr: container_memory_usage_bytes / container_spec_memory_limit_bytes > 0.9
    for: 2m
    labels:
      severity: critical
    annotations:
      summary: "High memory usage on {{ \$labels.pod }}"
\`\`\`

## 🔍 **Distributed Tracing**

\`\`\`yaml
# Jaeger Configuration
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jaeger
spec:
  template:
    spec:
      containers:
      - name: jaeger
        image: jaegertracing/all-in-one:latest
        env:
        - name: COLLECTOR_ZIPKIN_HTTP_PORT
          value: "9411"
\`\`\`

## ☁️ **AWS Integration**

- **CloudWatch Container Insights**: Native EKS monitoring
- **AWS X-Ray**: Distributed tracing for microservices
- **CloudWatch Logs**: Centralized log aggregation
- **AWS CloudTrail**: API audit logging

Would you like me to provide specific configuration examples for any of these monitoring components?`,

      security: `Here's a comprehensive DevSecOps implementation strategy:

## 🔒 **Security Pipeline Integration**

### 1. Source Code Security
\`\`\`yaml
# Static Application Security Testing (SAST)
- name: Run CodeQL Analysis
  uses: github/codeql-action/analyze@v2
  with:
    languages: javascript, python, java

- name: Run Semgrep SAST
  uses: returntocorp/semgrep-action@v1
  with:
    config: auto
\`\`\`

### 2. Dependency Scanning
\`\`\`yaml
# Software Composition Analysis (SCA)
- name: Run Snyk to check for vulnerabilities
  uses: snyk/actions/node@master
  env:
    SNYK_TOKEN: \${{ secrets.SNYK_TOKEN }}
  with:
    args: --severity-threshold=high

- name: OWASP Dependency Check
  uses: dependency-check/Dependency-Check_Action@main
  with:
    project: 'microservice'
    path: '.'
    format: 'ALL'
\`\`\`

### 3. Container Security
\`\`\`yaml
# Container Image Scanning
- name: Run Trivy vulnerability scanner
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: 'myapp:latest'
    format: 'sarif'
    output: 'trivy-results.sarif'

- name: Docker Scout
  uses: docker/scout-action@v1
  with:
    command: cves
    image: myapp:latest
\`\`\`

## 🛡️ **Runtime Security**

### Kubernetes Security Policies
\`\`\`yaml
# Pod Security Standards
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted

# Network Policies
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress
\`\`\`

### Falco Runtime Monitoring
\`\`\`yaml
# Detect suspicious activities
- rule: Unexpected outbound connection
  desc: Detect unexpected outbound connections
  condition: >
    outbound and not fd.typechar = 4 and not fd.is_unix_socket and not proc.name in (expected_programs)
  output: >
    Unexpected outbound connection (user=%user.name command=%proc.cmdline 
    connection=%fd.name)
  priority: WARNING
\`\`\`

## 🔐 **Secrets Management**

\`\`\`yaml
# External Secrets Operator
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secrets-manager
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets-sa
\`\`\`

## 📋 **Compliance Automation**

- **CIS Benchmarks**: Automated compliance scanning
- **SOC 2**: Continuous compliance monitoring
- **PCI DSS**: Payment card industry standards
- **GDPR**: Data protection compliance

Would you like me to dive deeper into any specific security aspect or compliance framework?`,

      default: `I'm your DevOps KnowledgeOps Agent, powered by Amazon Bedrock AgentCore! 

## 🎯 **How I Can Help**

**Infrastructure & Cloud:**
- Multi-cloud architecture (AWS, Azure, GCP)
- Infrastructure as Code (Terraform, CloudFormation, Pulumi)
- Container orchestration (Kubernetes, Docker, EKS)
- Network design and security

**CI/CD & Automation:**
- Pipeline design and optimization
- GitOps workflows and best practices
- Automated testing strategies
- Deployment patterns (blue-green, canary, rolling)

**Monitoring & Operations:**
- Observability stack setup (Prometheus, Grafana, ELK)
- SRE practices and incident response
- Performance optimization and troubleshooting
- Cost optimization strategies

**Security & Compliance:**
- DevSecOps implementation
- Vulnerability management and scanning
- Compliance automation (SOC2, PCI DSS, GDPR)
- Zero-trust architecture design

## 💡 **Try These Queries:**

- "Help me troubleshoot my EKS cluster issues"
- "Design a CI/CD pipeline for microservices"
- "What's the best monitoring setup for containers?"
- "How do I implement security scanning in my pipeline?"
- "Show me Terraform best practices for multi-environment setup"

**What specific DevOps challenge would you like help with?** The more details you provide about your environment and requirements, the better I can tailor my recommendations!`
    };
  }
}

export const apiService = new ApiService();
export default apiService;
