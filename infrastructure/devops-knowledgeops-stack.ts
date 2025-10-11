import * as cdk from 'aws-cdk-lib';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';

export class DevOpsKnowledgeOpsStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // S3 Bucket for Knowledge Base documents
    const knowledgeBucket = new s3.Bucket(this, 'DevOpsKnowledgeBucket', {
      bucketName: `devops-knowledge-${cdk.Aws.ACCOUNT_ID}-${cdk.Aws.REGION}`,
      removalPolicy: cdk.RemovalPolicy.DESTROY, // For demo purposes
      autoDeleteObjects: true, // For demo purposes
      versioned: false,
      publicReadAccess: false,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
    });

    // Cognito User Pool for authentication
    const userPool = new cognito.UserPool(this, 'DevOpsUserPool', {
      userPoolName: 'devops-knowledgeops-users',
      selfSignUpEnabled: true,
      signInAliases: {
        email: true,
        username: true,
      },
      autoVerify: {
        email: true,
      },
      passwordPolicy: {
        minLength: 8,
        requireLowercase: true,
        requireUppercase: true,
        requireDigits: true,
        requireSymbols: false,
      },
      removalPolicy: cdk.RemovalPolicy.DESTROY, // For demo purposes
    });

    // Cognito User Pool Client
    const userPoolClient = new cognito.UserPoolClient(this, 'DevOpsUserPoolClient', {
      userPool,
      userPoolClientName: 'devops-knowledgeops-client',
      generateSecret: false, // For web applications
      authFlows: {
        userPassword: true,
        userSrp: true,
      },
      oAuth: {
        flows: {
          authorizationCodeGrant: true,
        },
        scopes: [cognito.OAuthScope.OPENID, cognito.OAuthScope.EMAIL, cognito.OAuthScope.PROFILE],
      },
    });

    // DynamoDB table for chat sessions and messages
    const chatTable = new dynamodb.Table(this, 'ChatSessionsTable', {
      tableName: 'devops-chat-sessions',
      partitionKey: {
        name: 'sessionId',
        type: dynamodb.AttributeType.STRING,
      },
      sortKey: {
        name: 'messageId',
        type: dynamodb.AttributeType.STRING,
      },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY, // For demo purposes
      pointInTimeRecovery: false, // Simplified for demo
    });

    // Add GSI for user-based queries
    chatTable.addGlobalSecondaryIndex({
      indexName: 'UserIndex',
      partitionKey: {
        name: 'userId',
        type: dynamodb.AttributeType.STRING,
      },
      sortKey: {
        name: 'timestamp',
        type: dynamodb.AttributeType.NUMBER,
      },
    });

    // IAM role for Lambda functions
    const lambdaRole = new iam.Role(this, 'DevOpsLambdaRole', {
      assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSLambdaBasicExecutionRole'),
      ],
      inlinePolicies: {
        BedrockAccess: new iam.PolicyDocument({
          statements: [
            new iam.PolicyStatement({
              effect: iam.Effect.ALLOW,
              actions: [
                'bedrock:InvokeAgent',
                'bedrock:InvokeModel',
                'bedrock:GetAgent',
                'bedrock:ListAgents',
                'bedrock:CreateAgent',
                'bedrock:UpdateAgent',
                'bedrock:PrepareAgent',
                'bedrock:GetKnowledgeBase',
                'bedrock:ListKnowledgeBases',
                'bedrock-agent:*',
                'bedrock-agent-runtime:*',
              ],
              resources: ['*'],
            }),
          ],
        }),
        DynamoDBAccess: new iam.PolicyDocument({
          statements: [
            new iam.PolicyStatement({
              effect: iam.Effect.ALLOW,
              actions: [
                'dynamodb:GetItem',
                'dynamodb:PutItem',
                'dynamodb:UpdateItem',
                'dynamodb:DeleteItem',
                'dynamodb:Query',
                'dynamodb:Scan',
              ],
              resources: [chatTable.tableArn, `${chatTable.tableArn}/index/*`],
            }),
          ],
        }),
        S3Access: new iam.PolicyDocument({
          statements: [
            new iam.PolicyStatement({
              effect: iam.Effect.ALLOW,
              actions: [
                's3:GetObject',
                's3:PutObject',
                's3:DeleteObject',
                's3:ListBucket',
              ],
              resources: [knowledgeBucket.bucketArn, `${knowledgeBucket.bucketArn}/*`],
            }),
          ],
        }),
        CognitoAccess: new iam.PolicyDocument({
          statements: [
            new iam.PolicyStatement({
              effect: iam.Effect.ALLOW,
              actions: [
                'cognito-idp:AdminCreateUser',
                'cognito-idp:AdminSetUserPassword',
                'cognito-idp:AdminGetUser',
                'cognito-idp:InitiateAuth',
                'cognito-idp:GetUser',
              ],
              resources: [userPool.userPoolArn],
            }),
          ],
        }),
      },
    });

    // Authentication Lambda function
    const authLambda = new lambda.Function(this, 'AuthLambda', {
      functionName: 'devops-auth-handler',
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'auth-handler.handler',
      code: lambda.Code.fromAsset('lambda/auth'),
      role: lambdaRole,
      timeout: cdk.Duration.seconds(30),
      memorySize: 512,
      environment: {
        USER_POOL_ID: userPool.userPoolId,
        USER_POOL_CLIENT_ID: userPoolClient.userPoolClientId,
      },
    });

    // Session management Lambda function
    const sessionLambda = new lambda.Function(this, 'SessionLambda', {
      functionName: 'devops-session-handler',
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'session-handler.handler',
      code: lambda.Code.fromAsset('lambda/session'),
      role: lambdaRole,
      timeout: cdk.Duration.seconds(30),
      memorySize: 512,
      environment: {
        CHAT_TABLE_NAME: chatTable.tableName,
        USER_POOL_ID: userPool.userPoolId,
        USER_POOL_CLIENT_ID: userPoolClient.userPoolClientId,
      },
    });

    // Actions Lambda function
    const actionsLambda = new lambda.Function(this, 'ActionsLambda', {
      functionName: 'devops-actions-handler',
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'action-handler.handler',
      code: lambda.Code.fromAsset('lambda/actions'),
      role: lambdaRole,
      timeout: cdk.Duration.seconds(30),
      memorySize: 512,
      environment: {
        AWS_REGION: cdk.Aws.REGION,
      },
    });

    // Chat processing Lambda function
    const chatLambda = new lambda.Function(this, 'ChatProcessorLambda', {
      functionName: 'devops-chat-processor',
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('lambda/chat-processor'),
      role: lambdaRole,
      timeout: cdk.Duration.seconds(60), // Increased for Bedrock calls
      memorySize: 1024,
      environment: {
        CHAT_TABLE_NAME: chatTable.tableName,
        MEMORY_TABLE_NAME: chatTable.tableName,
        KNOWLEDGE_BUCKET_NAME: knowledgeBucket.bucketName,
        USER_POOL_ID: userPool.userPoolId,
        USER_POOL_CLIENT_ID: userPoolClient.userPoolClientId,
        BEDROCK_AGENT_ID: process.env.BEDROCK_AGENT_ID || '',
        BEDROCK_AGENT_ALIAS_ID: process.env.BEDROCK_AGENT_ALIAS_ID || 'TSTALIASID',
      },
    });

    // API Gateway for REST endpoints
    const api = new apigateway.RestApi(this, 'DevOpsKnowledgeOpsApi', {
      restApiName: 'devops-knowledgeops-api',
      description: 'API for DevOps KnowledgeOps Agent',
      defaultCorsPreflightOptions: {
        allowOrigins: apigateway.Cors.ALL_ORIGINS,
        allowMethods: apigateway.Cors.ALL_METHODS,
        allowHeaders: ['Content-Type', 'Authorization'],
      },
    });

    // Authentication endpoint
    const authResource = api.root.addResource('auth');
    authResource.addMethod('POST', new apigateway.LambdaIntegration(authLambda));

    // Session management endpoint
    const sessionResource = api.root.addResource('session');
    sessionResource.addMethod('POST', new apigateway.LambdaIntegration(sessionLambda));

    // Actions endpoint
    const actionsResource = api.root.addResource('actions');
    actionsResource.addMethod('POST', new apigateway.LambdaIntegration(actionsLambda));

    // Chat endpoint
    const chatResource = api.root.addResource('chat');
    chatResource.addMethod('POST', new apigateway.LambdaIntegration(chatLambda));

    // Health check endpoint
    const healthResource = api.root.addResource('health');
    healthResource.addMethod('GET', new apigateway.MockIntegration({
      integrationResponses: [{
        statusCode: '200',
        responseTemplates: {
          'application/json': JSON.stringify({
            status: 'healthy',
            timestamp: '$context.requestTime',
          }),
        },
      }],
      requestTemplates: {
        'application/json': '{"statusCode": 200}',
      },
    }), {
      methodResponses: [{
        statusCode: '200',
        responseModels: {
          'application/json': apigateway.Model.EMPTY_MODEL,
        },
      }],
    });

    // Output important values
    new cdk.CfnOutput(this, 'UserPoolId', {
      value: userPool.userPoolId,
      description: 'Cognito User Pool ID',
    });

    new cdk.CfnOutput(this, 'UserPoolClientId', {
      value: userPoolClient.userPoolClientId,
      description: 'Cognito User Pool Client ID',
    });

    new cdk.CfnOutput(this, 'ApiGatewayUrl', {
      value: api.url,
      description: 'API Gateway URL',
    });

    new cdk.CfnOutput(this, 'KnowledgeBucketName', {
      value: knowledgeBucket.bucketName,
      description: 'S3 Bucket for Knowledge Base',
    });

    new cdk.CfnOutput(this, 'ChatTableName', {
      value: chatTable.tableName,
      description: 'DynamoDB Table for Chat Sessions',
    });
  }
}