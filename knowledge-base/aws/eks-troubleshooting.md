# EKS Troubleshooting Guide

## Common EKS Issues and Solutions

### Pod Startup Issues

#### ImagePullBackOff Errors
**Symptoms**: Pods stuck in `ImagePullBackOff` or `ErrImagePull` status

**Common Causes**:
1. **Incorrect image name or tag**
2. **Missing ECR permissions**
3. **Network connectivity issues**
4. **Registry authentication problems**

**Troubleshooting Steps**:

1. **Check pod events**:
   ```bash
   kubectl describe pod <pod-name> -n <namespace>
   ```

2. **Verify image exists**:
   ```bash
   aws ecr describe-images --repository-name <repo-name> --region <region>
   ```

3. **Check ECR permissions**:
   ```bash
   aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account>.dkr.ecr.<region>.amazonaws.com
   ```

4. **Verify node IAM permissions**:
   - Ensure nodes have `AmazonEKSWorkerNodePolicy`
   - Ensure nodes have `AmazonEKS_CNI_Policy`
   - Ensure nodes have `AmazonEC2ContainerRegistryReadOnly`

#### CrashLoopBackOff Errors
**Symptoms**: Pods continuously restarting

**Troubleshooting**:
1. **Check application logs**:
   ```bash
   kubectl logs <pod-name> -n <namespace> --previous
   ```

2. **Check resource limits**:
   ```bash
   kubectl describe pod <pod-name> -n <namespace>
   ```

3. **Verify liveness/readiness probes**:
   ```yaml
   livenessProbe:
     httpGet:
       path: /health
       port: 8080
     initialDelaySeconds: 30
     periodSeconds: 10
   ```

### Networking Issues

#### Service Discovery Problems
**Symptoms**: Services cannot communicate with each other

**Solutions**:
1. **Check service endpoints**:
   ```bash
   kubectl get endpoints -n <namespace>
   ```

2. **Verify DNS resolution**:
   ```bash
   kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup <service-name>.<namespace>.svc.cluster.local
   ```

3. **Check network policies**:
   ```bash
   kubectl get networkpolicies -n <namespace>
   ```

#### Load Balancer Issues
**Common Problems**:
- Security groups blocking traffic
- Subnets not properly tagged
- Target group health checks failing

**Solutions**:
1. **Check ALB controller logs**:
   ```bash
   kubectl logs -n kube-system deployment/aws-load-balancer-controller
   ```

2. **Verify subnet tags**:
   ```
   kubernetes.io/role/elb = 1 (for public subnets)
   kubernetes.io/role/internal-elb = 1 (for private subnets)
   ```

### Node Issues

#### Node Not Ready
**Symptoms**: Nodes showing `NotReady` status

**Troubleshooting**:
1. **Check node conditions**:
   ```bash
   kubectl describe node <node-name>
   ```

2. **Check kubelet logs**:
   ```bash
   # SSH to node and check
   sudo journalctl -u kubelet -f
   ```

3. **Verify CNI plugin**:
   ```bash
   kubectl get pods -n kube-system | grep aws-node
   ```

#### Resource Exhaustion
**Symptoms**: Pods pending due to insufficient resources

**Solutions**:
1. **Check resource usage**:
   ```bash
   kubectl top nodes
   kubectl top pods --all-namespaces
   ```

2. **Scale cluster**:
   ```bash
   aws eks update-nodegroup-config --cluster-name <cluster> --nodegroup-name <nodegroup> --scaling-config minSize=<min>,maxSize=<max>,desiredSize=<desired>
   ```

### Storage Issues

#### PVC Stuck in Pending
**Common Causes**:
- No available storage class
- Insufficient permissions
- Zone mismatch

**Solutions**:
1. **Check storage classes**:
   ```bash
   kubectl get storageclass
   ```

2. **Verify EBS CSI driver**:
   ```bash
   kubectl get pods -n kube-system | grep ebs-csi
   ```

3. **Check PVC events**:
   ```bash
   kubectl describe pvc <pvc-name> -n <namespace>
   ```

## Best Practices for EKS Operations

### Monitoring and Observability
1. **Enable Container Insights**
2. **Use Prometheus and Grafana**
3. **Implement distributed tracing**
4. **Set up proper alerting**

### Security
1. **Use RBAC properly**
2. **Enable network policies**
3. **Scan container images**
4. **Use Pod Security Standards**

### Performance Optimization
1. **Right-size your nodes**
2. **Use horizontal pod autoscaling**
3. **Implement cluster autoscaling**
4. **Optimize container resource requests/limits**