#!/usr/bin/env ts-node

import { 
  BedrockAgentClient, 
  CreateAgentCommand, 
  PrepareAgentCommand,
  CreateAgentAliasCommand,
  CreateKnowledgeBaseCommand,
  CreateDataSourceCommand,
  StartIngestionJobCommand,
} from '@aws-sdk/client-bedrock-agent';
import { DEVOPS_AGENT_CONFIG } from '../lambda/bedrock/agent-config';

interface AgentSetupConfig {
  region: string;
  agentRoleArn: string;
  knowledgeBucketName: string;
  knowledgeBaseRoleArn: string;
}

class BedrockAgentSetup {
  private client: BedrockAgentClient;
  private config: AgentSetupConfig;

  constructor(config: AgentSetupConfig) {
    this.client = new BedrockAgentClient({ region: config.region });
    this.config = config;
  }

  async setupCompleteAgent(): Promise<{
    agentId: string;
    agentAliasId: string;
    knowledgeBaseId: string;
  }> {
    console.log('🚀 Starting Bedrock Agent setup...');

    try {
      // Step 1: Create Knowledge Base
      console.log('📚 Creating Knowledge Base...');
      const knowledgeBaseId = await this.createKnowledgeBase();
      
      // Step 2: Create Data Source
      console.log('📄 Creating Data Source...');
      const dataSourceId = await this.createDataSource(knowledgeBaseId);
      
      // Step 3: Start Ingestion Job
      console.log('🔄 Starting Knowledge Base ingestion...');
      await this.startIngestionJob(knowledgeBaseId, dataSourceId);
      
      // Step 4: Create Agent
      console.log('🤖 Creating Bedrock Agent...');
      const agentId = await this.createAgent(knowledgeBaseId);
      
      // Step 5: Prepare Agent
      console.log('⚙️ Preparing Agent...');
      await this.prepareAgent(agentId);
      
      // Step 6: Create Agent Alias
      console.log('🏷️ Creating Agent Alias...');
      const agentAliasId = await this.createAgentAlias(agentId);
      
      console.log('✅ Bedrock Agent setup completed successfully!');
      console.log(`Agent ID: ${agentId}`);
      console.log(`Agent Alias ID: ${agentAliasId}`);
      console.log(`Knowledge Base ID: ${knowledgeBaseId}`);
      
      return { agentId, agentAliasId, knowledgeBaseId };
      
    } catch (error) {
      console.error('❌ Error setting up Bedrock Agent:', error);
      throw error;
    }
  }

  private async createKnowledgeBase(): Promise<string> {
    const command = new CreateKnowledgeBaseCommand({
      name: 'DevOpsKnowledgeBase',
      description: 'Comprehensive DevOps knowledge base for the KnowledgeOps Agent',
      roleArn: this.config.knowledgeBaseRoleArn,
      knowledgeBaseConfiguration: {
        type: 'VECTOR',
        vectorKnowledgeBaseConfiguration: {
          embeddingModelArn: 'arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v1',
        },
      },
      storageConfiguration: {
        type: 'OPENSEARCH_SERVERLESS',
        opensearchServerlessConfiguration: {
          collectionArn: `arn:aws:aoss:${this.config.region}:${process.env.AWS_ACCOUNT_ID}:collection/devops-knowledge`,
          vectorIndexName: 'devops-knowledge-index',
          fieldMapping: {
            vectorField: 'vector',
            textField: 'text',
            metadataField: 'metadata',
          },
        },
      },
    });

    const response = await this.client.send(command);
    return response.knowledgeBase!.knowledgeBaseId!;
  }

  private async createDataSource(knowledgeBaseId: string): Promise<string> {
    const command = new CreateDataSourceCommand({
      knowledgeBaseId,
      name: 'DevOpsS3DataSource',
      description: 'S3 data source for DevOps documentation',
      dataSourceConfiguration: {
        type: 'S3',
        s3Configuration: {
          bucketArn: `arn:aws:s3:::${this.config.knowledgeBucketName}`,
          inclusionPrefixes: ['knowledge-base/'],
        },
      },
      vectorIngestionConfiguration: {
        chunkingConfiguration: {
          chunkingStrategy: 'FIXED_SIZE',
          fixedSizeChunkingConfiguration: {
            maxTokens: 300,
            overlapPercentage: 20,
          },
        },
      },
    });

    const response = await this.client.send(command);
    return response.dataSource!.dataSourceId!;
  }

  private async startIngestionJob(knowledgeBaseId: string, dataSourceId: string): Promise<void> {
    const command = new StartIngestionJobCommand({
      knowledgeBaseId,
      dataSourceId,
    });

    await this.client.send(command);
    console.log('📥 Ingestion job started. This may take a few minutes...');
  }

  private async createAgent(knowledgeBaseId: string): Promise<string> {
    const command = new CreateAgentCommand({
      agentName: DEVOPS_AGENT_CONFIG.agentName,
      description: DEVOPS_AGENT_CONFIG.description,
      foundationModel: DEVOPS_AGENT_CONFIG.foundationModel,
      instruction: DEVOPS_AGENT_CONFIG.instruction,
      agentResourceRoleArn: this.config.agentRoleArn,
      knowledgeBases: [
        {
          knowledgeBaseId,
          description: 'DevOps knowledge base with comprehensive documentation',
          knowledgeBaseState: 'ENABLED',
        },
      ],
    });

    const response = await this.client.send(command);
    return response.agent!.agentId!;
  }

  private async prepareAgent(agentId: string): Promise<void> {
    const command = new PrepareAgentCommand({
      agentId,
    });

    await this.client.send(command);
    console.log('🔧 Agent preparation completed');
  }

  private async createAgentAlias(agentId: string): Promise<string> {
    const command = new CreateAgentAliasCommand({
      agentId,
      agentAliasName: 'LIVE',
      description: 'Live alias for the DevOps KnowledgeOps Agent',
    });

    const response = await this.client.send(command);
    return response.agentAlias!.agentAliasId!;
  }
}

// Main execution
async function main() {
  const config: AgentSetupConfig = {
    region: process.env.AWS_REGION || 'us-east-1',
    agentRoleArn: process.env.AGENT_ROLE_ARN || '',
    knowledgeBucketName: process.env.KNOWLEDGE_BUCKET_NAME || '',
    knowledgeBaseRoleArn: process.env.KNOWLEDGE_BASE_ROLE_ARN || '',
  };

  if (!config.agentRoleArn || !config.knowledgeBucketName || !config.knowledgeBaseRoleArn) {
    console.error('❌ Missing required environment variables:');
    console.error('- AGENT_ROLE_ARN');
    console.error('- KNOWLEDGE_BUCKET_NAME');
    console.error('- KNOWLEDGE_BASE_ROLE_ARN');
    process.exit(1);
  }

  const setup = new BedrockAgentSetup(config);
  
  try {
    const result = await setup.setupCompleteAgent();
    
    console.log('\n🎉 Setup completed! Add these to your environment:');
    console.log(`export BEDROCK_AGENT_ID=${result.agentId}`);
    console.log(`export BEDROCK_AGENT_ALIAS_ID=${result.agentAliasId}`);
    console.log(`export BEDROCK_KNOWLEDGE_BASE_ID=${result.knowledgeBaseId}`);
    
  } catch (error) {
    console.error('❌ Setup failed:', error);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

export { BedrockAgentSetup };