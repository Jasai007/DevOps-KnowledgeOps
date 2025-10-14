import * as cdk from 'aws-cdk-lib';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as s3 from 'aws-cdk-lib/aws-s3';
import { Construct } from 'constructs';

export interface BedrockResourcesProps {
  knowledgeBucket: s3.Bucket;
}

export class BedrockResources extends Construct {
  public readonly agentRole: iam.Role;
  public readonly knowledgeBaseRole: iam.Role;

  constructor(scope: Construct, id: string, props: BedrockResourcesProps) {
    super(scope, id);

    // IAM Role for Bedrock Agent
    this.agentRole = new iam.Role(this, 'BedrockAgentRole', {
      roleName: `BedrockAgentRole-${cdk.Aws.REGION}`,
      assumedBy: new iam.ServicePrincipal('bedrock.amazonaws.com'),
      inlinePolicies: {
        BedrockAgentPolicy: new iam.PolicyDocument({
          statements: [
            new iam.PolicyStatement({
              effect: iam.Effect.ALLOW,
              actions: [
                'bedrock:InvokeModel',
                'bedrock:InvokeAgent',
                'bedrock:GetAgent',
                'bedrock:GetKnowledgeBase',
                'bedrock:Retrieve',
                'bedrock:RetrieveAndGenerate',
              ],
              resources: ['*'],
            }),
            new iam.PolicyStatement({
              effect: iam.Effect.ALLOW,
              actions: [
                'lambda:InvokeFunction',
              ],
              resources: [
                `arn:aws:lambda:${cdk.Aws.REGION}:${cdk.Aws.ACCOUNT_ID}:function:devops-actions-handler`,
              ],
            }),
          ],
        }),
      },
    });

    // IAM Role for Bedrock Knowledge Base
    this.knowledgeBaseRole = new iam.Role(this, 'BedrockKnowledgeBaseRole', {
      roleName: `BedrockKnowledgeBaseRole-${cdk.Aws.REGION}`,
      assumedBy: new iam.ServicePrincipal('bedrock.amazonaws.com'),
      inlinePolicies: {
        KnowledgeBasePolicy: new iam.PolicyDocument({
          statements: [
            new iam.PolicyStatement({
              effect: iam.Effect.ALLOW,
              actions: [
                's3:GetObject',
                's3:ListBucket',
              ],
              resources: [
                props.knowledgeBucket.bucketArn,
                `${props.knowledgeBucket.bucketArn}/*`,
              ],
            }),
            new iam.PolicyStatement({
              effect: iam.Effect.ALLOW,
              actions: [
                'bedrock:InvokeModel',
              ],
              resources: [
                `arn:aws:bedrock:${cdk.Aws.REGION}::foundation-model/amazon.titan-embed-text-v2:0`,
                `arn:aws:bedrock:${cdk.Aws.REGION}::foundation-model/amazon.titan-embed-text-v1`,
              ],
            }),
            new iam.PolicyStatement({
              effect: iam.Effect.ALLOW,
              actions: [
                'aoss:APIAccessAll',
              ],
              resources: ['*'], // OpenSearch Serverless collections
            }),
          ],
        }),
      },
    });

    // Output the role ARNs for use in Bedrock setup
    new cdk.CfnOutput(this, 'BedrockAgentRoleArn', {
      value: this.agentRole.roleArn,
      description: 'IAM Role ARN for Bedrock Agent',
      exportName: 'BedrockAgentRoleArn',
    });

    new cdk.CfnOutput(this, 'BedrockKnowledgeBaseRoleArn', {
      value: this.knowledgeBaseRole.roleArn,
      description: 'IAM Role ARN for Bedrock Knowledge Base',
      exportName: 'BedrockKnowledgeBaseRoleArn',
    });
  }
}