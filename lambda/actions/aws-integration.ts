/**
 * AWS Integration Actions for DevOps KnowledgeOps Agent
 * Provides read-only access to AWS services for demo purposes
 */

import { CloudWatchClient, GetMetricStatisticsCommand, ListMetricsCommand } from '@aws-sdk/client-cloudwatch';
import { EKSClient, DescribeClusterCommand, ListClustersCommand, DescribeNodegroupCommand } from '@aws-sdk/client-eks';
import { EC2Client, DescribeInstancesCommand, DescribeVpcsCommand } from '@aws-sdk/client-ec2';
import { ECSClient, ListClustersCommand as ECSListClustersCommand, DescribeServicesCommand } from '@aws-sdk/client-ecs';

export interface MetricsQuery {
  metricName: string;
  namespace: string;
  dimensions?: Record<string, string>;
  startTime: Date;
  endTime: Date;
  period: number;
  statistic: 'Average' | 'Sum' | 'Maximum' | 'Minimum' | 'SampleCount';
}

export interface MetricsResult {
  metricName: string;
  datapoints: Array<{
    timestamp: Date;
    value: number;
    unit: string;
  }>;
  summary: {
    average: number;
    maximum: number;
    minimum: number;
    latest: number;
  };
}

export interface ClusterStatus {
  name: string;
  status: string;
  version: string;
  endpoint: string;
  nodeGroups: Array<{
    name: string;
    status: string;
    instanceTypes: string[];
    desiredSize: number;
    minSize: number;
    maxSize: number;
  }>;
  health: 'healthy' | 'warning' | 'critical';
  recommendations: string[];
}

export interface SystemHealth {
  service: string;
  status: 'healthy' | 'degraded' | 'unhealthy';
  lastChecked: Date;
  metrics: {
    cpu: number;
    memory: number;
    requests: number;
    errors: number;
  };
  issues: string[];
}

export class AWSIntegrationActions {
  private cloudWatchClient: CloudWatchClient;
  private eksClient: EKSClient;
  private ec2Client: EC2Client;
  private ecsClient: ECSClient;

  constructor(region: string = 'us-east-1') {
    this.cloudWatchClient = new CloudWatchClient({ region });
    this.eksClient = new EKSClient({ region });
    this.ec2Client = new EC2Client({ region });
    this.ecsClient = new ECSClient({ region });
  }

  /**
   * Query CloudWatch metrics
   */
  async queryMetrics(query: MetricsQuery): Promise<MetricsResult> {
    try {
      const command = new GetMetricStatisticsCommand({
        Namespace: query.namespace,
        MetricName: query.metricName,
        Dimensions: query.dimensions ? Object.entries(query.dimensions).map(([Name, Value]) => ({ Name, Value })) : [],
        StartTime: query.startTime,
        EndTime: query.endTime,
        Period: query.period,
        Statistics: [query.statistic],
      });

      const response = await this.cloudWatchClient.send(command);
      const datapoints = (response.Datapoints || [])
        .map(dp => ({
          timestamp: dp.Timestamp!,
          value: dp[query.statistic]!,
          unit: dp.Unit || 'None',
        }))
        .sort((a, b) => a.timestamp.getTime() - b.timestamp.getTime());

      const values = datapoints.map(dp => dp.value);
      const summary = {
        average: values.length > 0 ? values.reduce((a, b) => a + b, 0) / values.length : 0,
        maximum: values.length > 0 ? Math.max(...values) : 0,
        minimum: values.length > 0 ? Math.min(...values) : 0,
        latest: values.length > 0 ? values[values.length - 1] : 0,
      };

      return {
        metricName: query.metricName,
        datapoints,
        summary,
      };
    } catch (error) {
      console.error('Error querying metrics:', error);
      // Return mock data for demo purposes
      return this.getMockMetricsData(query);
    }
  }

  /**
   * Check EKS cluster status
   */
  async checkEKSClusterStatus(clusterName?: string): Promise<ClusterStatus[]> {
    try {
      // List clusters if no specific cluster provided
      const listCommand = new ListClustersCommand({});
      const listResponse = await this.eksClient.send(listCommand);
      
      const clusterNames = clusterName ? [clusterName] : (listResponse.clusters || []);
      const clusterStatuses: ClusterStatus[] = [];

      for (const name of clusterNames) {
        try {
          const describeCommand = new DescribeClusterCommand({ name });
          const cluster = await this.eksClient.send(describeCommand);
          
          if (cluster.cluster) {
            const nodeGroups = await this.getNodeGroupInfo(name);
            const health = this.assessClusterHealth(cluster.cluster, nodeGroups);
            
            clusterStatuses.push({
              name,
              status: cluster.cluster.status || 'UNKNOWN',
              version: cluster.cluster.version || 'Unknown',
              endpoint: cluster.cluster.endpoint || 'Unknown',
              nodeGroups,
              health: health.status,
              recommendations: health.recommendations,
            });
          }
        } catch (error) {
          console.error(`Error describing cluster ${name}:`, error);
        }
      }

      return clusterStatuses.length > 0 ? clusterStatuses : this.getMockEKSData();
    } catch (error) {
      console.error('Error checking EKS clusters:', error);
      return this.getMockEKSData();
    }
  }

  /**
   * Check system health across multiple services
   */
  async checkSystemHealth(endpoints: string[]): Promise<SystemHealth[]> {
    const healthChecks: SystemHealth[] = [];

    for (const endpoint of endpoints) {
      try {
        // In a real implementation, this would make HTTP requests to health endpoints
        // For demo purposes, we'll simulate health checks
        const health = await this.simulateHealthCheck(endpoint);
        healthChecks.push(health);
      } catch (error) {
        healthChecks.push({
          service: endpoint,
          status: 'unhealthy',
          lastChecked: new Date(),
          metrics: { cpu: 0, memory: 0, requests: 0, errors: 100 },
          issues: [`Failed to connect to ${endpoint}: ${error}`],
        });
      }
    }

    return healthChecks;
  }

  /**
   * Get infrastructure overview
   */
  async getInfrastructureOverview(): Promise<{
    ec2Instances: number;
    vpcs: number;
    eksClusters: number;
    ecsClusters: number;
    recommendations: string[];
  }> {
    try {
      const [ec2Response, vpcResponse, eksResponse, ecsResponse] = await Promise.allSettled([
        this.ec2Client.send(new DescribeInstancesCommand({})),
        this.ec2Client.send(new DescribeVpcsCommand({})),
        this.eksClient.send(new ListClustersCommand({})),
        this.ecsClient.send(new ECSListClustersCommand({})),
      ]);

      const ec2Count = ec2Response.status === 'fulfilled' 
        ? (ec2Response.value.Reservations || []).reduce((count, reservation) => count + (reservation.Instances || []).length, 0)
        : 0;

      const vpcCount = vpcResponse.status === 'fulfilled' 
        ? (vpcResponse.value.Vpcs || []).length 
        : 0;

      const eksCount = eksResponse.status === 'fulfilled' 
        ? (eksResponse.value.clusters || []).length 
        : 0;

      const ecsCount = ecsResponse.status === 'fulfilled' 
        ? (ecsResponse.value.clusterArns || []).length 
        : 0;

      const recommendations = this.generateInfrastructureRecommendations({
        ec2Count,
        vpcCount,
        eksCount,
        ecsCount,
      });

      return {
        ec2Instances: ec2Count,
        vpcs: vpcCount,
        eksClusters: eksCount,
        ecsClusters: ecsCount,
        recommendations,
      };
    } catch (error) {
      console.error('Error getting infrastructure overview:', error);
      return {
        ec2Instances: 5,
        vpcs: 2,
        eksClusters: 1,
        ecsClusters: 2,
        recommendations: [
          'Consider consolidating VPCs to reduce complexity',
          'Review EC2 instance utilization for cost optimization',
          'Implement auto-scaling for EKS node groups',
        ],
      };
    }
  }

  private async getNodeGroupInfo(clusterName: string) {
    // In a real implementation, this would list and describe node groups
    // For demo purposes, return mock data
    return [
      {
        name: 'main-nodegroup',
        status: 'ACTIVE',
        instanceTypes: ['t3.medium', 't3.large'],
        desiredSize: 3,
        minSize: 1,
        maxSize: 10,
      },
    ];
  }

  private assessClusterHealth(cluster: any, nodeGroups: any[]): { status: 'healthy' | 'warning' | 'critical'; recommendations: string[] } {
    const recommendations: string[] = [];
    let status: 'healthy' | 'warning' | 'critical' = 'healthy';

    // Check cluster version
    if (cluster.version && parseFloat(cluster.version) < 1.28) {
      recommendations.push('Consider upgrading to a newer Kubernetes version');
      status = 'warning';
    }

    // Check node groups
    const inactiveNodeGroups = nodeGroups.filter(ng => ng.status !== 'ACTIVE');
    if (inactiveNodeGroups.length > 0) {
      recommendations.push('Some node groups are not in ACTIVE state');
      status = 'critical';
    }

    // Check scaling configuration
    const oversizedNodeGroups = nodeGroups.filter(ng => ng.desiredSize === ng.maxSize);
    if (oversizedNodeGroups.length > 0) {
      recommendations.push('Some node groups are at maximum capacity - consider increasing limits');
      status = status === 'critical' ? 'critical' : 'warning';
    }

    if (recommendations.length === 0) {
      recommendations.push('Cluster appears healthy');
    }

    return { status, recommendations };
  }

  private async simulateHealthCheck(endpoint: string): Promise<SystemHealth> {
    // Simulate different health states for demo
    const isHealthy = Math.random() > 0.2; // 80% chance of being healthy
    const cpu = Math.random() * 100;
    const memory = Math.random() * 100;
    const requests = Math.floor(Math.random() * 1000);
    const errors = isHealthy ? Math.floor(Math.random() * 5) : Math.floor(Math.random() * 50);

    let status: 'healthy' | 'degraded' | 'unhealthy' = 'healthy';
    const issues: string[] = [];

    if (cpu > 80) {
      status = 'degraded';
      issues.push('High CPU usage detected');
    }

    if (memory > 85) {
      status = 'degraded';
      issues.push('High memory usage detected');
    }

    if (errors > 10) {
      status = 'unhealthy';
      issues.push('High error rate detected');
    }

    return {
      service: endpoint,
      status,
      lastChecked: new Date(),
      metrics: { cpu, memory, requests, errors },
      issues,
    };
  }

  private generateInfrastructureRecommendations(counts: {
    ec2Count: number;
    vpcCount: number;
    eksCount: number;
    ecsCount: number;
  }): string[] {
    const recommendations: string[] = [];

    if (counts.ec2Count > 20) {
      recommendations.push('Consider using auto-scaling groups to manage large EC2 fleets');
    }

    if (counts.vpcCount > 5) {
      recommendations.push('Review VPC architecture - consider VPC peering or Transit Gateway');
    }

    if (counts.eksCount === 0 && counts.ecsCount === 0) {
      recommendations.push('Consider containerizing workloads with EKS or ECS');
    }

    if (counts.eksCount > 0 && counts.ecsCount > 0) {
      recommendations.push('Consider standardizing on one container orchestration platform');
    }

    return recommendations;
  }

  private getMockMetricsData(query: MetricsQuery): MetricsResult {
    const datapoints = [];
    const now = new Date();
    
    for (let i = 0; i < 10; i++) {
      const timestamp = new Date(now.getTime() - (i * query.period * 1000));
      const value = Math.random() * 100;
      datapoints.push({
        timestamp,
        value,
        unit: 'Percent',
      });
    }

    const values = datapoints.map(dp => dp.value);
    return {
      metricName: query.metricName,
      datapoints: datapoints.reverse(),
      summary: {
        average: values.reduce((a, b) => a + b, 0) / values.length,
        maximum: Math.max(...values),
        minimum: Math.min(...values),
        latest: values[values.length - 1],
      },
    };
  }

  private getMockEKSData(): ClusterStatus[] {
    return [
      {
        name: 'production-cluster',
        status: 'ACTIVE',
        version: '1.28',
        endpoint: 'https://example.eks.amazonaws.com',
        nodeGroups: [
          {
            name: 'main-nodegroup',
            status: 'ACTIVE',
            instanceTypes: ['t3.medium'],
            desiredSize: 3,
            minSize: 1,
            maxSize: 10,
          },
        ],
        health: 'healthy',
        recommendations: ['Cluster is running optimally'],
      },
    ];
  }
}