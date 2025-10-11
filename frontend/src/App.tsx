import React, { useState, useEffect, useRef } from 'react';
import {
  Box,
  Container,
  Paper,
  Typography,
  TextField,
  Button,
  Avatar,
  Chip,
  CircularProgress,
  Alert,
  Fade,
  Slide,
} from '@mui/material';
import {
  Send as SendIcon,
  SmartToy as BotIcon,
  Person as PersonIcon,
  Code as CodeIcon,
  Cloud as CloudIcon,
  Security as SecurityIcon,
  Build as BuildIcon,
} from '@mui/icons-material';
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';
import { vscDarkPlus } from 'react-syntax-highlighter/dist/esm/styles/prism';
import './App.css';
import { apiService } from './services/api';

interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
  typing?: boolean;
}

interface ChatSession {
  sessionId: string;
  messages: Message[];
}

const DEMO_SUGGESTIONS = [
  { text: "Help me troubleshoot EKS pod failures", icon: <CloudIcon /> },
  { text: "Design a CI/CD pipeline for microservices", icon: <BuildIcon /> },
  { text: "What's the best monitoring setup for containers?", icon: <CodeIcon /> },
  { text: "How do I implement security scanning in my pipeline?", icon: <SecurityIcon /> },
];

function App() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputValue, setInputValue] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [session, setSession] = useState<ChatSession | null>(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [showSuggestions, setShowSuggestions] = useState(true);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    // Initialize with welcome message
    const welcomeMessage: Message = {
      id: 'welcome',
      role: 'assistant',
      content: `👋 Welcome to the DevOps KnowledgeOps Agent!

I'm your AI-powered DevOps expert, built with Amazon Bedrock AgentCore and enhanced with Strands reasoning capabilities. I can help you with:

🔧 **Infrastructure & Cloud**: AWS, Azure, GCP, hybrid setups
🚀 **CI/CD Pipelines**: GitHub Actions, Jenkins, GitLab CI, AWS CodePipeline  
📦 **Containers**: Docker, Kubernetes, EKS, container orchestration
📊 **Monitoring**: Prometheus, Grafana, CloudWatch, observability
🔒 **Security**: DevSecOps practices, compliance, vulnerability management
⚡ **Automation**: Terraform, Ansible, Infrastructure as Code
🐛 **Troubleshooting**: System debugging, performance optimization

Try asking me about any DevOps challenge you're facing!`,
      timestamp: new Date(),
    };

    setMessages([welcomeMessage]);
    setIsAuthenticated(true); // For demo purposes, skip auth
    scrollToBottom();
  }, []);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const handleSendMessage = async (messageText?: string) => {
    const text = messageText || inputValue.trim();
    if (!text || isLoading) return;

    setShowSuggestions(false);
    setInputValue('');
    setIsLoading(true);

    // Add user message
    const userMessage: Message = {
      id: Date.now().toString(),
      role: 'user',
      content: text,
      timestamp: new Date(),
    };

    setMessages(prev => [...prev, userMessage]);

    // Add typing indicator
    const typingMessage: Message = {
      id: 'typing',
      role: 'assistant',
      content: '',
      timestamp: new Date(),
      typing: true,
    };

    setMessages(prev => [...prev, typingMessage]);

    try {
      // Simulate API call delay for demo
      await new Promise(resolve => setTimeout(resolve, 1500));

      // Get response from API service (using mock for demo)
      const apiResponse = await apiService.getMockChatResponse(text);
      const response = apiResponse.response || 'Sorry, I encountered an error processing your request.';

      // Remove typing indicator and add real response
      setMessages(prev => {
        const filtered = prev.filter(msg => msg.id !== 'typing');
        return [...filtered, {
          id: Date.now().toString(),
          role: 'assistant',
          content: response,
          timestamp: new Date(),
        }];
      });

    } catch (error) {
      console.error('Error sending message:', error);
      setMessages(prev => {
        const filtered = prev.filter(msg => msg.id !== 'typing');
        return [...filtered, {
          id: Date.now().toString(),
          role: 'assistant',
          content: '❌ I encountered an issue processing your request. Please try again.',
          timestamp: new Date(),
        }];
      });
    } finally {
      setIsLoading(false);
    }
  };

  const handleKeyPress = (event: React.KeyboardEvent) => {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault();
      handleSendMessage();
    }
  };

  const renderMessage = (message: Message) => {
    const isUser = message.role === 'user';
    
    return (
      <Fade in={true} key={message.id}>
        <Box
          sx={{
            display: 'flex',
            justifyContent: isUser ? 'flex-end' : 'flex-start',
            mb: 2,
            alignItems: 'flex-start',
          }}
        >
          {!isUser && (
            <Avatar
              sx={{
                bgcolor: 'primary.main',
                mr: 1,
                width: 32,
                height: 32,
              }}
            >
              <BotIcon fontSize="small" />
            </Avatar>
          )}
          
          <Paper
            elevation={1}
            sx={{
              p: 2,
              maxWidth: '70%',
              bgcolor: isUser ? 'primary.main' : 'grey.100',
              color: isUser ? 'white' : 'text.primary',
              borderRadius: 2,
              position: 'relative',
            }}
          >
            {message.typing ? (
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <CircularProgress size={16} />
                <Typography variant="body2">Thinking...</Typography>
              </Box>
            ) : (
              <MessageContent content={message.content} />
            )}
            
            <Typography
              variant="caption"
              sx={{
                display: 'block',
                mt: 1,
                opacity: 0.7,
                fontSize: '0.7rem',
              }}
            >
              {message.timestamp.toLocaleTimeString()}
            </Typography>
          </Paper>

          {isUser && (
            <Avatar
              sx={{
                bgcolor: 'secondary.main',
                ml: 1,
                width: 32,
                height: 32,
              }}
            >
              <PersonIcon fontSize="small" />
            </Avatar>
          )}
        </Box>
      </Fade>
    );
  };

  return (
    <Box sx={{ height: '100vh', display: 'flex', flexDirection: 'column', bgcolor: 'grey.50' }}>
      {/* Header */}
      <Paper elevation={2} sx={{ p: 2, bgcolor: 'primary.main', color: 'white' }}>
        <Container maxWidth="md">
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
            <Avatar sx={{ bgcolor: 'primary.dark' }}>
              <BotIcon />
            </Avatar>
            <Box>
              <Typography variant="h6" component="h1">
                DevOps KnowledgeOps Agent
              </Typography>
              <Typography variant="body2" sx={{ opacity: 0.9 }}>
                Powered by Amazon Bedrock AgentCore + Strands
              </Typography>
            </Box>
            <Box sx={{ ml: 'auto', display: 'flex', gap: 1 }}>
              <Chip label="AgentCore" size="small" variant="outlined" sx={{ color: 'white', borderColor: 'white' }} />
              <Chip label="Strands" size="small" variant="outlined" sx={{ color: 'white', borderColor: 'white' }} />
              <Chip label="Live Demo" size="small" sx={{ bgcolor: 'success.main', color: 'white' }} />
            </Box>
          </Box>
        </Container>
      </Paper>

      {/* Chat Area */}
      <Container maxWidth="md" sx={{ flex: 1, display: 'flex', flexDirection: 'column', py: 2 }}>
        <Box sx={{ flex: 1, overflow: 'auto', mb: 2 }}>
          {messages.map(renderMessage)}
          
          {/* Suggestions */}
          {showSuggestions && messages.length <= 1 && (
            <Slide direction="up" in={showSuggestions}>
              <Box sx={{ mt: 3 }}>
                <Typography variant="h6" gutterBottom color="text.secondary">
                  Try these example queries:
                </Typography>
                <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1 }}>
                  {DEMO_SUGGESTIONS.map((suggestion, index) => (
                    <Chip
                      key={index}
                      icon={suggestion.icon}
                      label={suggestion.text}
                      onClick={() => handleSendMessage(suggestion.text)}
                      clickable
                      variant="outlined"
                      sx={{ mb: 1 }}
                    />
                  ))}
                </Box>
              </Box>
            </Slide>
          )}
          
          <div ref={messagesEndRef} />
        </Box>

        {/* Input Area */}
        <Paper elevation={2} sx={{ p: 2 }}>
          <Box sx={{ display: 'flex', gap: 1, alignItems: 'flex-end' }}>
            <TextField
              fullWidth
              multiline
              maxRows={4}
              value={inputValue}
              onChange={(e) => setInputValue(e.target.value)}
              onKeyPress={handleKeyPress}
              placeholder="Ask me anything about DevOps..."
              variant="outlined"
              disabled={isLoading}
              sx={{
                '& .MuiOutlinedInput-root': {
                  borderRadius: 2,
                },
              }}
            />
            <Button
              variant="contained"
              onClick={() => handleSendMessage()}
              disabled={!inputValue.trim() || isLoading}
              sx={{
                minWidth: 56,
                height: 56,
                borderRadius: 2,
              }}
            >
              {isLoading ? <CircularProgress size={24} /> : <SendIcon />}
            </Button>
          </Box>
        </Paper>
      </Container>
    </Box>
  );
}

// Component to render message content with code highlighting
const MessageContent: React.FC<{ content: string }> = ({ content }) => {
  const parts = content.split(/(```[\s\S]*?```)/);
  
  return (
    <>
      {parts.map((part, index) => {
        if (part.startsWith('```') && part.endsWith('```')) {
          const lines = part.slice(3, -3).split('\n');
          const language = lines[0].trim() || 'text';
          const code = lines.slice(1).join('\n');
          
          return (
            <Box key={index} sx={{ my: 1 }}>
              <SyntaxHighlighter
                language={language}
                style={vscDarkPlus}
                customStyle={{
                  borderRadius: 8,
                  fontSize: '0.875rem',
                }}
              >
                {code}
              </SyntaxHighlighter>
            </Box>
          );
        } else {
          return (
            <Typography
              key={index}
              variant="body1"
              component="div"
              sx={{
                whiteSpace: 'pre-wrap',
                '& strong': { fontWeight: 'bold' },
              }}
              dangerouslySetInnerHTML={{
                __html: part
                  .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
                  .replace(/\*(.*?)\*/g, '<em>$1</em>')
                  .replace(/`(.*?)`/g, '<code style="background: rgba(0,0,0,0.1); padding: 2px 4px; border-radius: 4px;">$1</code>')
              }}
            />
          );
        }
      })}
    </>
  );
};

// Mock API response function
async function getMockResponse(message: string): Promise<string> {
  const lowerMessage = message.toLowerCase();
  
  if (lowerMessage.includes('kubernetes') || lowerMessage.includes('k8s') || lowerMessage.includes('pod')) {
    return `For Kubernetes troubleshooting, I recommend following this systematic approach:

**1. Check Pod Status**:
\`\`\`bash
kubectl get pods -n <namespace>
kubectl describe pod <pod-name> -n <namespace>
\`\`\`

**2. Examine Logs**:
\`\`\`bash
kubectl logs <pod-name> -n <namespace> --previous
\`\`\`

**3. Check Resource Constraints**:
\`\`\`bash
kubectl top pods -n <namespace>
kubectl describe nodes
\`\`\`

**4. Verify Network Connectivity**:
\`\`\`bash
kubectl get svc -n <namespace>
kubectl get endpoints -n <namespace>
\`\`\`

Would you like me to dive deeper into any specific aspect of your Kubernetes issue?`;
  }
  
  if (lowerMessage.includes('terraform') || lowerMessage.includes('infrastructure')) {
    return `Here are Terraform best practices for multi-environment setups:

**1. Directory Structure**
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

**2. Use Workspaces or Separate State Files**
\`\`\`bash
# Option 1: Workspaces
terraform workspace new dev
terraform workspace select dev

# Option 2: Separate backends
terraform init -backend-config="key=dev/terraform.tfstate"
\`\`\`

**3. Variable Management**
\`\`\`hcl
# terraform.tfvars.example
environment = "dev"
instance_type = "t3.micro"
min_size = 1
max_size = 3
\`\`\`

Would you like me to elaborate on any of these practices?`;
  }
  
  if (lowerMessage.includes('cicd') || lowerMessage.includes('pipeline') || lowerMessage.includes('github actions')) {
    return `For a microservices CI/CD pipeline with GitHub Actions and AWS, here's a recommended architecture:

**Pipeline Structure**

\`\`\`yaml
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

**Key Components:**
- **ECR** for container registry
- **EKS** for orchestration  
- **ALB** for load balancing
- **Route53** for DNS
- **CloudWatch** for monitoring

Would you like me to detail any specific part of this pipeline?`;
  }
  
  if (lowerMessage.includes('monitoring') || lowerMessage.includes('prometheus') || lowerMessage.includes('grafana')) {
    return `For EKS monitoring, I recommend this comprehensive observability stack:

**Core Components**

**1. Metrics Collection**
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

**2. Visualization**
- **Grafana** for dashboards
- **Pre-built dashboards** for Kubernetes metrics
- **Custom dashboards** for application metrics

**3. AWS Integration**
- **CloudWatch Container Insights**
- **AWS X-Ray** for distributed tracing
- **AWS CloudTrail** for audit logs

Would you like me to provide specific configuration examples for any of these components?`;
  }
  
  if (lowerMessage.includes('security') || lowerMessage.includes('devsecops') || lowerMessage.includes('compliance')) {
    return `Implementing DevSecOps requires integrating security at every stage of your pipeline:

**1. Source Code Security**

**Static Analysis**
\`\`\`yaml
# GitHub Actions security scanning
- name: Run security scan
  uses: github/super-linter@v4
  env:
    DEFAULT_BRANCH: main
    GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
\`\`\`

**2. Container Security**

**Image Scanning**
\`\`\`bash
# Trivy container scanning
trivy image --severity HIGH,CRITICAL myapp:latest
\`\`\`

**3. Infrastructure Security**

**Policy as Code**
\`\`\`hcl
# OPA/Gatekeeper policies
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: k8srequiredsecuritycontext
\`\`\`

**4. Secrets Management**
- **AWS Secrets Manager** or **HashiCorp Vault**
- **External Secrets Operator** for Kubernetes
- **Sealed Secrets** for GitOps workflows

Would you like me to dive deeper into any specific security aspect?`;
  }
  
  // Default response
  return `I understand you're looking for DevOps guidance. As your AI-powered DevOps expert with Bedrock AgentCore and Strands integration, I can help you with:

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

Could you please provide more specific details about your DevOps challenge? The more context you give me, the better I can tailor my recommendations to your specific situation.`;
}

export default App;