# GitHub Actions CI/CD with AWS

## Complete CI/CD Pipeline for AWS Deployment

### Basic Workflow Structure

```yaml
name: Deploy to AWS
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  AWS_REGION: us-east-1
  ECR_REPOSITORY: my-app
  EKS_CLUSTER_NAME: production-cluster

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run tests
        run: npm test
      
      - name: Run security scan
        run: npm audit --audit-level high

  build:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    outputs:
      image-tag: ${{ steps.build-image.outputs.image-tag }}
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}
      
      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2
      
      - name: Build and push Docker image
        id: build-image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          echo "image-tag=$IMAGE_TAG" >> $GITHUB_OUTPUT

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment: production
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}
      
      - name: Update kubeconfig
        run: |
          aws eks update-kubeconfig --name ${{ env.EKS_CLUSTER_NAME }} --region ${{ env.AWS_REGION }}
      
      - name: Deploy to EKS
        env:
          IMAGE_TAG: ${{ needs.build.outputs.image-tag }}
        run: |
          sed -i "s|IMAGE_TAG|$IMAGE_TAG|g" k8s/deployment.yaml
          kubectl apply -f k8s/
          kubectl rollout status deployment/my-app -n production
```

## Advanced Patterns

### Multi-Environment Deployment

```yaml
name: Multi-Environment Deploy

on:
  push:
    branches: [main, develop, staging]

jobs:
  determine-environment:
    runs-on: ubuntu-latest
    outputs:
      environment: ${{ steps.env.outputs.environment }}
      cluster-name: ${{ steps.env.outputs.cluster-name }}
    steps:
      - id: env
        run: |
          if [[ "${{ github.ref }}" == "refs/heads/main" ]]; then
            echo "environment=production" >> $GITHUB_OUTPUT
            echo "cluster-name=prod-cluster" >> $GITHUB_OUTPUT
          elif [[ "${{ github.ref }}" == "refs/heads/staging" ]]; then
            echo "environment=staging" >> $GITHUB_OUTPUT
            echo "cluster-name=staging-cluster" >> $GITHUB_OUTPUT
          else
            echo "environment=development" >> $GITHUB_OUTPUT
            echo "cluster-name=dev-cluster" >> $GITHUB_OUTPUT
          fi

  deploy:
    needs: determine-environment
    runs-on: ubuntu-latest
    environment: ${{ needs.determine-environment.outputs.environment }}
    
    steps:
      - name: Deploy to ${{ needs.determine-environment.outputs.environment }}
        run: |
          echo "Deploying to ${{ needs.determine-environment.outputs.environment }}"
          # Deployment steps here
```

### Infrastructure as Code Integration

```yaml
name: Terraform Deploy

on:
  push:
    branches: [main]
    paths: ['terraform/**']

jobs:
  terraform:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: terraform
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.0
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      
      - name: Terraform Init
        run: terraform init
      
      - name: Terraform Plan
        run: terraform plan -out=tfplan
      
      - name: Terraform Apply
        if: github.ref == 'refs/heads/main'
        run: terraform apply tfplan
```

### Security Scanning Integration

```yaml
name: Security Pipeline

on: [push, pull_request]

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-results.sarif'
      
      - name: Upload Trivy scan results
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: 'trivy-results.sarif'
      
      - name: Container Image Scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'my-app:latest'
          format: 'table'
          exit-code: '1'
          severity: 'CRITICAL,HIGH'
```

## Best Practices

### Secret Management

```yaml
# Use GitHub Secrets for sensitive data
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: ${{ env.AWS_REGION }}

# Use OIDC for enhanced security (recommended)
- name: Configure AWS credentials with OIDC
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsRole
    aws-region: ${{ env.AWS_REGION }}
```

### Caching Strategies

```yaml
- name: Cache Docker layers
  uses: actions/cache@v3
  with:
    path: /tmp/.buildx-cache
    key: ${{ runner.os }}-buildx-${{ github.sha }}
    restore-keys: |
      ${{ runner.os }}-buildx-

- name: Cache npm dependencies
  uses: actions/cache@v3
  with:
    path: ~/.npm
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-node-
```

### Matrix Builds

```yaml
strategy:
  matrix:
    environment: [dev, staging, prod]
    include:
      - environment: dev
        aws-region: us-east-1
        cluster-name: dev-cluster
      - environment: staging
        aws-region: us-west-2
        cluster-name: staging-cluster
      - environment: prod
        aws-region: us-east-1
        cluster-name: prod-cluster

steps:
  - name: Deploy to ${{ matrix.environment }}
    run: |
      aws eks update-kubeconfig --name ${{ matrix.cluster-name }} --region ${{ matrix.aws-region }}
```

### Conditional Deployments

```yaml
- name: Deploy to production
  if: github.ref == 'refs/heads/main' && github.event_name == 'push'
  run: |
    # Production deployment steps

- name: Deploy to staging
  if: github.ref == 'refs/heads/develop'
  run: |
    # Staging deployment steps
```

## Monitoring and Notifications

### Slack Integration

```yaml
- name: Notify Slack on success
  if: success()
  uses: 8398a7/action-slack@v3
  with:
    status: success
    text: 'Deployment to production succeeded! 🚀'
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}

- name: Notify Slack on failure
  if: failure()
  uses: 8398a7/action-slack@v3
  with:
    status: failure
    text: 'Deployment failed! 💥'
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

### Deployment Status Checks

```yaml
- name: Wait for deployment
  run: |
    kubectl rollout status deployment/my-app -n production --timeout=300s

- name: Run smoke tests
  run: |
    # Health check endpoint
    curl -f http://my-app.example.com/health || exit 1
    
    # Basic functionality test
    npm run test:smoke
```

## Troubleshooting Common Issues

### Authentication Problems
```yaml
# Debug AWS credentials
- name: Debug AWS credentials
  run: |
    aws sts get-caller-identity
    aws eks describe-cluster --name ${{ env.EKS_CLUSTER_NAME }}
```

### Docker Build Issues
```yaml
# Enable Docker buildkit for better error messages
- name: Set up Docker Buildx
  uses: docker/setup-buildx-action@v3

# Multi-stage build optimization
- name: Build with cache
  uses: docker/build-push-action@v5
  with:
    context: .
    push: true
    tags: ${{ env.ECR_REGISTRY }}/${{ env.ECR_REPOSITORY }}:${{ github.sha }}
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

### Kubernetes Deployment Issues
```yaml
- name: Debug Kubernetes deployment
  if: failure()
  run: |
    kubectl get pods -n production
    kubectl describe deployment my-app -n production
    kubectl logs -l app=my-app -n production --tail=100
```

## Performance Optimization

### Parallel Jobs
```yaml
jobs:
  test:
    strategy:
      matrix:
        test-type: [unit, integration, e2e]
    runs-on: ubuntu-latest
    steps:
      - name: Run ${{ matrix.test-type }} tests
        run: npm run test:${{ matrix.test-type }}
```

### Artifact Management
```yaml
- name: Upload build artifacts
  uses: actions/upload-artifact@v3
  with:
    name: build-artifacts
    path: dist/

- name: Download build artifacts
  uses: actions/download-artifact@v3
  with:
    name: build-artifacts
    path: dist/
```