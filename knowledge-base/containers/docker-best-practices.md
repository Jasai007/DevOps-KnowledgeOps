# Docker Best Practices

## Dockerfile Optimization

### Multi-Stage Builds
Use multi-stage builds to reduce image size and improve security:

```dockerfile
# Build stage
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Production stage
FROM node:18-alpine AS production
WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# Copy only necessary files
COPY --from=builder /app/node_modules ./node_modules
COPY --chown=nextjs:nodejs . .

USER nextjs
EXPOSE 3000
CMD ["npm", "start"]
```

### Layer Optimization
Order instructions to maximize cache efficiency:

```dockerfile
# Good: Dependencies change less frequently than source code
FROM node:18-alpine
WORKDIR /app

# Copy package files first (cached if unchanged)
COPY package*.json ./
RUN npm ci --only=production

# Copy source code last
COPY . .

# Bad: Source code changes invalidate all subsequent layers
FROM node:18-alpine
WORKDIR /app
COPY . .  # This invalidates cache for everything below
RUN npm ci --only=production
```

### Security Best Practices

#### Use Non-Root Users
```dockerfile
# Create and use non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser
USER appuser

# Or use numeric UID for better security
USER 1001:1001
```

#### Minimize Attack Surface
```dockerfile
# Use distroless or minimal base images
FROM gcr.io/distroless/nodejs18-debian11

# Remove unnecessary packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*
```

#### Scan for Vulnerabilities
```bash
# Use Trivy for vulnerability scanning
trivy image myapp:latest

# Use Docker Scout
docker scout cves myapp:latest
```

## Image Size Optimization

### Choose Appropriate Base Images
```dockerfile
# Alpine Linux (smallest)
FROM node:18-alpine  # ~40MB

# Debian slim
FROM node:18-slim    # ~80MB

# Full Debian (avoid for production)
FROM node:18         # ~400MB

# Distroless (most secure)
FROM gcr.io/distroless/nodejs18-debian11  # ~50MB
```

### Use .dockerignore
```dockerignore
# .dockerignore
node_modules
npm-debug.log
.git
.gitignore
README.md
.env
.nyc_output
coverage
.nyc_output
.coverage
.vscode
.idea
```

### Minimize Layers
```dockerfile
# Good: Combine RUN commands
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Bad: Multiple RUN commands create more layers
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y git
RUN rm -rf /var/lib/apt/lists/*
```

## Container Runtime Best Practices

### Resource Limits
```yaml
# Kubernetes deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    spec:
      containers:
      - name: myapp
        image: myapp:latest
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
```

```bash
# Docker run with limits
docker run -d \
  --memory="256m" \
  --cpus="0.5" \
  --name myapp \
  myapp:latest
```

### Health Checks
```dockerfile
# Dockerfile health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1
```

```yaml
# Kubernetes health checks
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /ready
    port: 3000
  initialDelaySeconds: 5
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 3
```

### Logging Best Practices
```dockerfile
# Log to stdout/stderr (not files)
CMD ["node", "server.js"]

# Use structured logging
# In your application:
console.log(JSON.stringify({
  level: 'info',
  message: 'Server started',
  port: 3000,
  timestamp: new Date().toISOString()
}));
```

## Development Workflow

### Docker Compose for Local Development
```yaml
# docker-compose.yml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "3000:3000"
    volumes:
      - .:/app
      - /app/node_modules
    environment:
      - NODE_ENV=development
    depends_on:
      - db
      - redis

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  postgres_data:
```

### Development vs Production Images
```dockerfile
# Dockerfile.dev
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install  # Include dev dependencies
COPY . .
CMD ["npm", "run", "dev"]

# Dockerfile (production)
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
USER 1001
CMD ["npm", "start"]
```

## Container Registry Best Practices

### Image Tagging Strategy
```bash
# Semantic versioning
docker tag myapp:latest myapp:1.2.3
docker tag myapp:latest myapp:1.2
docker tag myapp:latest myapp:1

# Git-based tagging
docker tag myapp:latest myapp:${GIT_COMMIT_SHA}
docker tag myapp:latest myapp:${GIT_BRANCH}

# Environment-specific tags
docker tag myapp:latest myapp:prod-1.2.3
docker tag myapp:latest myapp:staging-latest
```

### Registry Security
```bash
# Use private registries
docker login your-registry.com

# Sign images with Docker Content Trust
export DOCKER_CONTENT_TRUST=1
docker push myapp:latest

# Use registry webhooks for automated scanning
```

## Monitoring and Observability

### Container Metrics
```yaml
# Prometheus monitoring
apiVersion: v1
kind: Service
metadata:
  name: myapp-metrics
  labels:
    app: myapp
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "9090"
    prometheus.io/path: "/metrics"
spec:
  ports:
  - port: 9090
    name: metrics
  selector:
    app: myapp
```

### Distributed Tracing
```javascript
// OpenTelemetry setup
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');

const sdk = new NodeSDK({
  instrumentations: [getNodeAutoInstrumentations()],
});

sdk.start();
```

## Security Hardening

### Runtime Security
```yaml
# Pod Security Context
apiVersion: v1
kind: Pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1001
    fsGroup: 1001
  containers:
  - name: myapp
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
```

### Network Security
```yaml
# Network Policy
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: myapp-netpol
spec:
  podSelector:
    matchLabels:
      app: myapp
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 3000
```

### Secrets Management
```yaml
# Use Kubernetes secrets
apiVersion: v1
kind: Secret
metadata:
  name: myapp-secrets
type: Opaque
data:
  database-password: <base64-encoded-password>

# Mount as environment variables
env:
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: myapp-secrets
      key: database-password
```

## Performance Optimization

### Build Performance
```dockerfile
# Use build cache mounts
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci --only=production
```

### Runtime Performance
```bash
# Use init system for proper signal handling
docker run --init myapp:latest

# Optimize for container startup
docker run --memory-swappiness=0 myapp:latest
```

### Image Optimization Tools
```bash
# Use dive to analyze image layers
dive myapp:latest

# Use docker-slim to optimize images
docker-slim build --target myapp:latest --tag myapp:slim
```

## Troubleshooting

### Common Issues
```bash
# Debug container startup
docker logs myapp-container

# Execute commands in running container
docker exec -it myapp-container /bin/sh

# Inspect container configuration
docker inspect myapp-container

# Check resource usage
docker stats myapp-container
```

### Performance Debugging
```bash
# Profile container performance
docker run --rm -it --pid container:myapp-container \
  nicolaka/netshoot top

# Network debugging
docker run --rm -it --net container:myapp-container \
  nicolaka/netshoot netstat -tulpn
```