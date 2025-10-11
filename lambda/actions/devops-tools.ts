/**
 * DevOps Tools Action Group
 * Provides helper functions for common DevOps tasks
 */

export interface TerraformValidationResult {
  valid: boolean;
  errors: string[];
  warnings: string[];
  suggestions: string[];
}

export interface KubernetesManifest {
  apiVersion: string;
  kind: string;
  metadata: {
    name: string;
    namespace?: string;
    labels?: Record<string, string>;
  };
  spec: any;
}

export interface DockerfileAnalysis {
  issues: string[];
  optimizations: string[];
  securityConcerns: string[];
  bestPractices: string[];
}

export class DevOpsToolsActions {
  
  /**
   * Validate Terraform syntax and provide suggestions
   */
  async validateTerraformSyntax(code: string): Promise<TerraformValidationResult> {
    const result: TerraformValidationResult = {
      valid: true,
      errors: [],
      warnings: [],
      suggestions: []
    };

    try {
      // Basic syntax validation
      const lines = code.split('\n');
      let braceCount = 0;
      let inString = false;
      let stringChar = '';

      for (let i = 0; i < lines.length; i++) {
        const line = lines[i].trim();
        const lineNum = i + 1;

        // Skip comments and empty lines
        if (line.startsWith('#') || line.startsWith('//') || line === '') {
          continue;
        }

        // Check for common syntax issues
        for (let j = 0; j < line.length; j++) {
          const char = line[j];
          
          if (!inString) {
            if (char === '"' || char === "'") {
              inString = true;
              stringChar = char;
            } else if (char === '{') {
              braceCount++;
            } else if (char === '}') {
              braceCount--;
              if (braceCount < 0) {
                result.errors.push(`Line ${lineNum}: Unmatched closing brace`);
                result.valid = false;
              }
            }
          } else {
            if (char === stringChar && line[j-1] !== '\\') {
              inString = false;
              stringChar = '';
            }
          }
        }

        // Check for common patterns and best practices
        if (line.includes('resource "') && !line.includes('{')) {
          if (i + 1 < lines.length && !lines[i + 1].trim().startsWith('{')) {
            result.warnings.push(`Line ${lineNum}: Resource block should be followed by opening brace`);
          }
        }

        // Check for hardcoded values
        if (line.match(/= "[\d.]+"/)) {
          result.suggestions.push(`Line ${lineNum}: Consider using variables for hardcoded values`);
        }

        // Check for missing tags
        if (line.includes('resource "aws_') && !code.includes('tags')) {
          result.suggestions.push(`Consider adding tags to AWS resources for better organization`);
        }
      }

      // Check for unmatched braces
      if (braceCount !== 0) {
        result.errors.push(`Unmatched braces: ${braceCount > 0 ? 'missing closing' : 'extra closing'} braces`);
        result.valid = false;
      }

      // Check for best practices
      if (!code.includes('terraform {')) {
        result.suggestions.push('Consider adding terraform block with required_version and required_providers');
      }

      if (!code.includes('variable ') && code.includes('var.')) {
        result.warnings.push('Variables are referenced but not defined');
      }

      if (!code.includes('output ') && code.includes('resource ')) {
        result.suggestions.push('Consider adding outputs for important resource attributes');
      }

    } catch (error) {
      result.valid = false;
      result.errors.push(`Validation error: ${error}`);
    }

    return result;
  }

  /**
   * Generate Kubernetes YAML manifest based on requirements
   */
  async generateKubernetesManifest(requirements: {
    type: 'deployment' | 'service' | 'configmap' | 'secret';
    name: string;
    namespace?: string;
    image?: string;
    replicas?: number;
    ports?: number[];
    env?: Record<string, string>;
    labels?: Record<string, string>;
  }): Promise<KubernetesManifest[]> {
    const manifests: KubernetesManifest[] = [];
    const { type, name, namespace = 'default', image, replicas = 1, ports = [80], env = {}, labels = {} } = requirements;

    const commonLabels = {
      app: name,
      ...labels
    };

    switch (type) {
      case 'deployment':
        if (!image) {
          throw new Error('Image is required for deployment');
        }

        manifests.push({
          apiVersion: 'apps/v1',
          kind: 'Deployment',
          metadata: {
            name,
            namespace,
            labels: commonLabels
          },
          spec: {
            replicas,
            selector: {
              matchLabels: commonLabels
            },
            template: {
              metadata: {
                labels: commonLabels
              },
              spec: {
                containers: [{
                  name,
                  image,
                  ports: ports.map(port => ({ containerPort: port })),
                  env: Object.entries(env).map(([key, value]) => ({ name: key, value })),
                  resources: {
                    requests: {
                      memory: '128Mi',
                      cpu: '100m'
                    },
                    limits: {
                      memory: '256Mi',
                      cpu: '200m'
                    }
                  },
                  livenessProbe: {
                    httpGet: {
                      path: '/health',
                      port: ports[0]
                    },
                    initialDelaySeconds: 30,
                    periodSeconds: 10
                  },
                  readinessProbe: {
                    httpGet: {
                      path: '/ready',
                      port: ports[0]
                    },
                    initialDelaySeconds: 5,
                    periodSeconds: 5
                  }
                }]
              }
            }
          }
        });
        break;

      case 'service':
        manifests.push({
          apiVersion: 'v1',
          kind: 'Service',
          metadata: {
            name,
            namespace,
            labels: commonLabels
          },
          spec: {
            selector: commonLabels,
            ports: ports.map((port, index) => ({
              name: `port-${index}`,
              port,
              targetPort: port,
              protocol: 'TCP'
            })),
            type: 'ClusterIP'
          }
        });
        break;

      case 'configmap':
        manifests.push({
          apiVersion: 'v1',
          kind: 'ConfigMap',
          metadata: {
            name,
            namespace,
            labels: commonLabels
          },
          spec: {
            data: env
          }
        });
        break;

      case 'secret':
        manifests.push({
          apiVersion: 'v1',
          kind: 'Secret',
          metadata: {
            name,
            namespace,
            labels: commonLabels
          },
          spec: {
            type: 'Opaque',
            data: Object.fromEntries(
              Object.entries(env).map(([key, value]) => [key, Buffer.from(value).toString('base64')])
            )
          }
        });
        break;
    }

    return manifests;
  }

  /**
   * Analyze Dockerfile and provide optimization suggestions
   */
  async analyzeDockerfile(dockerfile: string): Promise<DockerfileAnalysis> {
    const analysis: DockerfileAnalysis = {
      issues: [],
      optimizations: [],
      securityConcerns: [],
      bestPractices: []
    };

    const lines = dockerfile.split('\n').map(line => line.trim()).filter(line => line && !line.startsWith('#'));

    // Check for common issues
    const fromLines = lines.filter(line => line.toUpperCase().startsWith('FROM'));
    if (fromLines.length === 0) {
      analysis.issues.push('No FROM instruction found');
    }

    // Check for latest tag usage
    if (dockerfile.includes(':latest')) {
      analysis.securityConcerns.push('Using :latest tag is not recommended for production');
      analysis.bestPractices.push('Pin specific image versions for reproducible builds');
    }

    // Check for root user
    if (!dockerfile.includes('USER ')) {
      analysis.securityConcerns.push('Container runs as root user');
      analysis.bestPractices.push('Create and use a non-root user');
    }

    // Check for multi-stage builds
    if (fromLines.length === 1 && dockerfile.includes('npm install')) {
      analysis.optimizations.push('Consider using multi-stage builds to reduce image size');
    }

    // Check for layer optimization
    const runCommands = lines.filter(line => line.toUpperCase().startsWith('RUN'));
    if (runCommands.length > 3) {
      analysis.optimizations.push('Consider combining RUN commands to reduce layers');
    }

    // Check for .dockerignore
    if (!dockerfile.includes('COPY') && !dockerfile.includes('ADD')) {
      analysis.bestPractices.push('Use COPY instead of ADD when possible');
    }

    // Check for health checks
    if (!dockerfile.includes('HEALTHCHECK')) {
      analysis.bestPractices.push('Add HEALTHCHECK instruction for better container monitoring');
    }

    // Check for exposed ports
    if (!dockerfile.includes('EXPOSE')) {
      analysis.bestPractices.push('Document exposed ports with EXPOSE instruction');
    }

    // Check for package manager cache cleanup
    if (dockerfile.includes('apt-get install') && !dockerfile.includes('rm -rf /var/lib/apt/lists/*')) {
      analysis.optimizations.push('Clean up package manager cache to reduce image size');
    }

    if (dockerfile.includes('npm install') && !dockerfile.includes('npm cache clean')) {
      analysis.optimizations.push('Clean npm cache after installation');
    }

    // Security checks
    if (dockerfile.includes('curl') || dockerfile.includes('wget')) {
      analysis.securityConcerns.push('Be cautious when downloading files during build');
    }

    if (dockerfile.includes('chmod 777')) {
      analysis.securityConcerns.push('Avoid using 777 permissions');
    }

    return analysis;
  }

  /**
   * Generate CI/CD pipeline configuration
   */
  async generateCICDPipeline(requirements: {
    platform: 'github-actions' | 'gitlab-ci' | 'jenkins';
    language: 'node' | 'python' | 'java' | 'go';
    deployTarget: 'kubernetes' | 'ecs' | 'lambda';
    includeTests: boolean;
    includeSecurity: boolean;
  }): Promise<string> {
    const { platform, language, deployTarget, includeTests, includeSecurity } = requirements;

    if (platform === 'github-actions') {
      return this.generateGitHubActionsPipeline(language, deployTarget, includeTests, includeSecurity);
    } else if (platform === 'gitlab-ci') {
      return this.generateGitLabCIPipeline(language, deployTarget, includeTests, includeSecurity);
    } else {
      return this.generateJenkinsPipeline(language, deployTarget, includeTests, includeSecurity);
    }
  }

  private generateGitHubActionsPipeline(language: string, deployTarget: string, includeTests: boolean, includeSecurity: boolean): string {
    let pipeline = `name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  AWS_REGION: us-east-1

jobs:`;

    if (includeTests) {
      pipeline += `
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup ${language}
        uses: actions/setup-${language}@v4
        with:
          ${language}-version: 'latest'
      
      - name: Install dependencies
        run: ${this.getInstallCommand(language)}
      
      - name: Run tests
        run: ${this.getTestCommand(language)}`;
    }

    if (includeSecurity) {
      pipeline += `
  
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run security scan
        uses: securecodewarrior/github-action-add-sarif@v1
        with:
          sarif-file: security-results.sarif`;
    }

    pipeline += `
  
  build:
    runs-on: ubuntu-latest
    ${includeTests ? 'needs: test' : ''}
    steps:
      - uses: actions/checkout@v4
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: \${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: \${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: \${{ env.AWS_REGION }}
      
      - name: Build and push
        run: |
          ${this.getBuildCommands(deployTarget)}`;

    return pipeline;
  }

  private generateGitLabCIPipeline(language: string, deployTarget: string, includeTests: boolean, includeSecurity: boolean): string {
    return `stages:
  - test
  - security
  - build
  - deploy

variables:
  AWS_DEFAULT_REGION: us-east-1

${includeTests ? `test:
  stage: test
  image: ${language}:latest
  script:
    - ${this.getInstallCommand(language)}
    - ${this.getTestCommand(language)}
` : ''}

${includeSecurity ? `security:
  stage: security
  image: securecodewarrior/sast-scan
  script:
    - sast-scan
` : ''}

build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - ${this.getBuildCommands(deployTarget)}`;
  }

  private generateJenkinsPipeline(language: string, deployTarget: string, includeTests: boolean, includeSecurity: boolean): string {
    return `pipeline {
    agent any
    
    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
    }
    
    stages {
        ${includeTests ? `stage('Test') {
            steps {
                sh '${this.getInstallCommand(language)}'
                sh '${this.getTestCommand(language)}'
            }
        }` : ''}
        
        ${includeSecurity ? `stage('Security') {
            steps {
                sh 'security-scan'
            }
        }` : ''}
        
        stage('Build') {
            steps {
                sh '''
                    ${this.getBuildCommands(deployTarget)}
                '''
            }
        }
    }
}`;
  }

  private getInstallCommand(language: string): string {
    const commands = {
      node: 'npm ci',
      python: 'pip install -r requirements.txt',
      java: 'mvn install -DskipTests',
      go: 'go mod download'
    };
    return commands[language as keyof typeof commands] || 'echo "Unknown language"';
  }

  private getTestCommand(language: string): string {
    const commands = {
      node: 'npm test',
      python: 'pytest',
      java: 'mvn test',
      go: 'go test ./...'
    };
    return commands[language as keyof typeof commands] || 'echo "No tests configured"';
  }

  private getBuildCommands(deployTarget: string): string {
    const commands = {
      kubernetes: `docker build -t myapp:latest .
docker tag myapp:latest $ECR_REGISTRY/myapp:$GITHUB_SHA
docker push $ECR_REGISTRY/myapp:$GITHUB_SHA
kubectl set image deployment/myapp myapp=$ECR_REGISTRY/myapp:$GITHUB_SHA`,
      ecs: `docker build -t myapp:latest .
aws ecs update-service --cluster production --service myapp --force-new-deployment`,
      lambda: `zip -r function.zip .
aws lambda update-function-code --function-name myapp --zip-file fileb://function.zip`
    };
    return commands[deployTarget as keyof typeof commands] || 'echo "Unknown deploy target"';
  }
}