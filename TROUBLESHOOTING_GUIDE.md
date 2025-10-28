# CloudWave API Troubleshooting Guide

## 🚨 Container Restart Issues

### Error: "Back-off restarting failed container"

This error means your container is crashing and Kubernetes keeps trying to restart it. Let's diagnose and fix it.

## 🔍 Diagnostic Steps

### Step 1: Check Pod Status
```bash
# Get detailed pod information
kubectl get pods -n cloudwave -l app=cloudwave-api

# Get pod events (most important for diagnosis)
kubectl describe pod -n cloudwave -l app=cloudwave-api

# Check pod logs
kubectl logs -n cloudwave -l app=cloudwave-api --previous
```

### Step 2: Common Issues and Solutions

#### Issue 1: Image Pull Problems
**Symptoms**: `ImagePullBackOff` or `ErrImagePull`

**Check**:
```bash
# Verify image exists in Docker Hub
docker pull docker.io/YOUR_USERNAME/cloudwave-api:COMMIT_SHA

# Check if image name is correct in deployment
kubectl get deployment cloudwave-api -n cloudwave -o yaml | grep image:
```

**Solutions**:
- Verify Docker Hub repository exists and is public
- Check image tag matches what was pushed by CI/CD
- Ensure no typos in image name

#### Issue 2: Application Startup Failures
**Symptoms**: Container starts but crashes immediately

**Check**:
```bash
# Get application logs
kubectl logs -n cloudwave -l app=cloudwave-api

# Check if Java application is starting properly
kubectl logs -n cloudwave -l app=cloudwave-api | grep -i error
```

**Common Java/Spring Boot Issues**:
- Port binding issues (app not listening on port 8080)
- Missing dependencies
- Configuration errors
- JVM memory issues

#### Issue 3: Resource Constraints
**Symptoms**: Container killed due to resource limits

**Check**:
```bash
# Check resource usage
kubectl top pods -n cloudwave

# Check resource limits
kubectl describe deployment cloudwave-api -n cloudwave | grep -A 10 "Limits\|Requests"
```

**Solution**: Adjust resource limits in deployment

#### Issue 4: Health Check Failures
**Symptoms**: Container runs but fails readiness/liveness probes

**Check**:
```bash
# Test health endpoints manually
kubectl port-forward -n cloudwave svc/cloudwave-api-svc 8080:80
curl http://localhost:8080/
curl http://localhost:8080/health
```

## 🛠️ Quick Fixes

### Fix 1: Update Resource Limits
If the container is being killed due to memory limits:

```yaml
# In k8s/base/deployment.yaml
resources:
  requests:
    memory: "512Mi"  # Increased from 256Mi
    cpu: "250m"
  limits:
    memory: "1Gi"    # Increased from 512Mi
    cpu: "500m"
```

### Fix 2: Adjust Health Check Timing
If health checks are failing due to slow startup:

```yaml
# In k8s/base/deployment.yaml
readinessProbe:
  httpGet:
    path: /
    port: 8080
  initialDelaySeconds: 30  # Increased from 5
  periodSeconds: 10
livenessProbe:
  httpGet:
    path: /
    port: 8080
  initialDelaySeconds: 60  # Increased from 10
  periodSeconds: 20
```

### Fix 3: Verify Application Port
Ensure your Spring Boot app is listening on the correct port:

```java
# In application.properties (if it exists)
server.port=8080

# Or check if port is hardcoded in Java code
@SpringBootApplication
@RestController
public class DevopsSampleApplication {
    // Should be listening on port 8080
}
```

### Fix 4: Add Debug Information
Temporarily add debug logging to see what's happening:

```yaml
# In k8s/base/deployment.yaml, add environment variables
env:
- name: JAVA_OPTS
  value: "-Xms256m -Xmx512m -Djava.awt.headless=true"
- name: SPRING_PROFILES_ACTIVE
  value: "debug"
```

## 🔧 Immediate Troubleshooting Commands

Run these commands to get detailed information:

```bash
# 1. Get current pod status
kubectl get pods -n cloudwave -o wide

# 2. Get detailed pod description (events are crucial)
kubectl describe pod -n cloudwave $(kubectl get pods -n cloudwave -l app=cloudwave-api -o jsonpath='{.items[0].metadata.name}')

# 3. Get current logs
kubectl logs -n cloudwave -l app=cloudwave-api --tail=50

# 4. Get previous container logs (if container restarted)
kubectl logs -n cloudwave -l app=cloudwave-api --previous --tail=50

# 5. Check deployment status
kubectl rollout status deployment/cloudwave-api -n cloudwave

# 6. Check service endpoints
kubectl get endpoints -n cloudwave
```

## 🚀 Testing Locally

To verify your application works locally:

```bash
# Build and test locally
mvn clean package
java -jar target/cloudwave-api-0.0.1-SNAPSHOT.jar

# Test endpoints
curl http://localhost:8080/
curl http://localhost:8080/health

# Build Docker image locally
docker build -t cloudwave-api-test .
docker run -p 8080:8080 cloudwave-api-test

# Test in container
curl http://localhost:8080/
```

## 📋 Checklist for Container Issues

- [ ] Image exists in Docker Hub and is accessible
- [ ] Image tag matches what's in kustomization.yaml
- [ ] Application starts successfully locally
- [ ] Application listens on port 8080
- [ ] Health endpoints (/ and /health) respond correctly
- [ ] Resource limits are sufficient
- [ ] No configuration errors in application
- [ ] Namespace exists and is correct
- [ ] Service account has necessary permissions

## 🔄 Recovery Steps

### Option 1: Rollback to Previous Version
```bash
# Check rollout history
kubectl rollout history deployment/cloudwave-api -n cloudwave

# Rollback to previous version
kubectl rollout undo deployment/cloudwave-api -n cloudwave
```

### Option 2: Force Restart
```bash
# Restart deployment
kubectl rollout restart deployment/cloudwave-api -n cloudwave
```

### Option 3: Scale Down and Up
```bash
# Scale to 0 replicas
kubectl scale deployment cloudwave-api --replicas=0 -n cloudwave

# Wait a moment, then scale back up
kubectl scale deployment cloudwave-api --replicas=2 -n cloudwave
```

## 📞 Getting Help

If you're still having issues, gather this information:

1. **Pod describe output**: `kubectl describe pod -n cloudwave -l app=cloudwave-api`
2. **Pod logs**: `kubectl logs -n cloudwave -l app=cloudwave-api --previous`
3. **Deployment yaml**: `kubectl get deployment cloudwave-api -n cloudwave -o yaml`
4. **Image details**: What image tag is being used
5. **Local testing results**: Does the app work locally?

This information will help identify the root cause of the container restart issue.