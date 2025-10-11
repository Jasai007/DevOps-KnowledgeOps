#!/usr/bin/env ts-node

import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { readdirSync, readFileSync, statSync } from 'fs';
import { join, extname, relative } from 'path';

interface KnowledgeDocument {
  key: string;
  content: string;
  category: string;
  title: string;
}

class KnowledgeBaseUploader {
  private s3Client: S3Client;
  private bucketName: string;

  constructor(region: string = 'us-east-1') {
    this.s3Client = new S3Client({ region });
    this.bucketName = process.env.KNOWLEDGE_BUCKET_NAME || 'devops-knowledge-bucket';
  }

  async uploadKnowledgeBase(knowledgeBasePath: string): Promise<void> {
    console.log(`📚 Starting knowledge base upload from ${knowledgeBasePath}`);
    
    const documents = this.scanDirectory(knowledgeBasePath);
    console.log(`📄 Found ${documents.length} documents to upload`);

    for (const doc of documents) {
      await this.uploadDocument(doc);
    }

    console.log('✅ Knowledge base upload completed!');
  }

  private scanDirectory(dirPath: string, category: string = ''): KnowledgeDocument[] {
    const documents: KnowledgeDocument[] = [];
    const items = readdirSync(dirPath);

    for (const item of items) {
      const fullPath = join(dirPath, item);
      const stat = statSync(fullPath);

      if (stat.isDirectory()) {
        // Recursively scan subdirectories
        const subCategory = category ? `${category}/${item}` : item;
        documents.push(...this.scanDirectory(fullPath, subCategory));
      } else if (extname(item) === '.md') {
        // Process markdown files
        const content = readFileSync(fullPath, 'utf-8');
        const relativePath = relative('knowledge-base', fullPath);
        const title = this.extractTitle(content) || item.replace('.md', '');
        
        documents.push({
          key: relativePath,
          content,
          category: category || 'general',
          title,
        });
      }
    }

    return documents;
  }

  private extractTitle(content: string): string | null {
    const titleMatch = content.match(/^#\s+(.+)$/m);
    return titleMatch ? titleMatch[1].trim() : null;
  }

  private async uploadDocument(doc: KnowledgeDocument): Promise<void> {
    try {
      const metadata = {
        category: doc.category,
        title: doc.title,
        'content-type': 'text/markdown',
        'upload-timestamp': new Date().toISOString(),
      };

      const command = new PutObjectCommand({
        Bucket: this.bucketName,
        Key: `knowledge-base/${doc.key}`,
        Body: doc.content,
        ContentType: 'text/markdown',
        Metadata: metadata,
      });

      await this.s3Client.send(command);
      console.log(`✓ Uploaded: ${doc.key} (${doc.category})`);
    } catch (error) {
      console.error(`✗ Failed to upload ${doc.key}:`, error);
    }
  }

  async createSampleDocuments(): Promise<void> {
    console.log('📝 Creating additional sample documents...');

    const sampleDocs = [
      {
        key: 'monitoring/prometheus-setup.md',
        category: 'monitoring',
        title: 'Prometheus Setup Guide',
        content: `# Prometheus Setup Guide

## Installation on Kubernetes

### Using Helm
\`\`\`bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack
\`\`\`

### Configuration
\`\`\`yaml
prometheus:
  prometheusSpec:
    retention: 30d
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: gp2
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi
\`\`\`

## Common Queries
- CPU Usage: \`rate(cpu_usage_seconds_total[5m])\`
- Memory Usage: \`container_memory_usage_bytes / container_spec_memory_limit_bytes\`
- Pod Restart Count: \`increase(kube_pod_container_status_restarts_total[1h])\`
`
      },
      {
        key: 'security/devsecops-practices.md',
        category: 'security',
        title: 'DevSecOps Best Practices',
        content: `# DevSecOps Best Practices

## Shift Left Security

### Static Code Analysis
- Use tools like SonarQube, CodeQL, or Semgrep
- Integrate into CI/CD pipelines
- Set quality gates for security issues

### Dependency Scanning
\`\`\`yaml
# GitHub Actions example
- name: Run Snyk to check for vulnerabilities
  uses: snyk/actions/node@master
  env:
    SNYK_TOKEN: \${{ secrets.SNYK_TOKEN }}
\`\`\`

### Container Security
- Scan images with Trivy or Clair
- Use distroless base images
- Implement runtime security with Falco

## Infrastructure Security
- Use Infrastructure as Code (Terraform, CloudFormation)
- Implement policy as code (OPA, Sentinel)
- Regular compliance scanning with tools like Scout Suite
`
      },
      {
        key: 'troubleshooting/common-issues.md',
        category: 'troubleshooting',
        title: 'Common DevOps Issues and Solutions',
        content: `# Common DevOps Issues and Solutions

## Application Performance Issues

### High CPU Usage
1. Check resource limits and requests
2. Profile application performance
3. Look for inefficient algorithms or loops
4. Consider horizontal scaling

### Memory Leaks
1. Monitor memory usage over time
2. Use profiling tools (pprof, heapdump)
3. Check for unclosed connections
4. Review garbage collection settings

## Infrastructure Issues

### Network Connectivity
1. Check security groups and NACLs
2. Verify DNS resolution
3. Test with telnet or nc
4. Review load balancer health checks

### Storage Issues
1. Check disk space and inodes
2. Verify mount points
3. Review I/O performance metrics
4. Check for permission issues

## CI/CD Pipeline Failures

### Build Failures
1. Check dependency versions
2. Verify environment variables
3. Review build logs for errors
4. Test locally with same conditions

### Deployment Issues
1. Verify image tags and availability
2. Check resource quotas
3. Review configuration changes
4. Validate health checks
`
      }
    ];

    for (const doc of sampleDocs) {
      await this.uploadDocument(doc);
    }

    console.log('✅ Sample documents created!');
  }
}

// Main execution
async function main() {
  const uploader = new KnowledgeBaseUploader();
  
  try {
    // Upload existing knowledge base documents
    await uploader.uploadKnowledgeBase('./knowledge-base');
    
    // Create additional sample documents
    await uploader.createSampleDocuments();
    
    console.log('🎉 Knowledge base setup completed successfully!');
  } catch (error) {
    console.error('❌ Error setting up knowledge base:', error);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

export { KnowledgeBaseUploader };