#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { DevOpsKnowledgeOpsStack } from './devops-knowledgeops-stack';

const app = new cdk.App();

// Get environment configuration
const account = process.env.CDK_DEFAULT_ACCOUNT || process.env.AWS_ACCOUNT_ID;
const region = process.env.CDK_DEFAULT_REGION || process.env.AWS_REGION || 'us-east-1';

new DevOpsKnowledgeOpsStack(app, 'DevOpsKnowledgeOpsStack', {
  env: {
    account: account,
    region: region,
  },
  description: 'DevOps KnowledgeOps Agent - AI-powered DevOps assistant using Bedrock AgentCore',
});

app.synth();