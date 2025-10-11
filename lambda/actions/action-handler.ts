import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { DevOpsToolsActions } from './devops-tools';
import { AWSIntegrationActions } from './aws-integration';

interface ActionRequest {
  action: string;
  parameters: any;
}

const devopsTools = new DevOpsToolsActions();
const awsIntegration = new AWSIntegrationActions();

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  const headers = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization',
    'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
  };

  try {
    // Handle CORS preflight
    if (event.httpMethod === 'OPTIONS') {
      return {
        statusCode: 200,
        headers,
        body: '',
      };
    }

    if (!event.body) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'Request body is required' }),
      };
    }

    const request: ActionRequest = JSON.parse(event.body);

    switch (request.action) {
      case 'validate-terraform':
        const terraformResult = await devopsTools.validateTerraformSyntax(request.parameters.code);
        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({
            success: true,
            result: terraformResult,
          }),
        };

      case 'generate-k8s-manifest':
        const manifests = await devopsTools.generateKubernetesManifest(request.parameters);
        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({
            success: true,
            result: manifests,
          }),
        };

      case 'analyze-dockerfile':
        const dockerAnalysis = await devopsTools.analyzeDockerfile(request.parameters.dockerfile);
        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({
            success: true,
            result: dockerAnalysis,
          }),
        };

      case 'generate-cicd-pipeline':
        const pipeline = await devopsTools.generateCICDPipeline(request.parameters);
        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({
            success: true,
            result: { pipeline },
          }),
        };

      case 'query-cloudwatch-metrics':
        const metricsResult = await awsIntegration.queryMetrics(request.parameters);
        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({
            success: true,
            result: metricsResult,
          }),
        };

      case 'check-eks-cluster':
        const clusterStatus = await awsIntegration.checkEKSClusterStatus(request.parameters.clusterName);
        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({
            success: true,
            result: clusterStatus,
          }),
        };

      case 'check-system-health':
        const healthStatus = await awsIntegration.checkSystemHealth(request.parameters.endpoints);
        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({
            success: true,
            result: healthStatus,
          }),
        };

      case 'get-infrastructure-overview':
        const overview = await awsIntegration.getInfrastructureOverview();
        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({
            success: true,
            result: overview,
          }),
        };

      default:
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: 'Unknown action' }),
        };
    }
  } catch (error: any) {
    console.error('Action handler error:', error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ 
        error: 'Internal server error',
        message: error.message 
      }),
    };
  }
};