# Multi-Service Setup: Java API + WordPress

This repository now supports deploying both a Java Spring Boot API and WordPress with MySQL database using GitOps with ArgoCD.

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Java API      │    │   WordPress     │    │     MySQL       │
│   (Port 8080)   │    │   (Port 80)     │    │   (Port 3306)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │     Ingress     │
                    │  (nginx-based)  │
                    └─────────────────┘
```

## Services Included

### 1. Java Spring Boot API (CloudWave API)
- **Image**: `docker.io/eknathdj/cloudwave-api:latest`
- **Port**: 8080
- **Health Checks**: `/health` endpoint
- **Access**: `http://api.cloudwave.local`

### 2. WordPress
- **Image**: `docker.io/eknathdj/cloudwave-wordpress:latest`
- **Port**: 80
- **Database**: MySQL 8.0
- **Access**: `http://wordpress.cloudwave.local`

### 3. MySQL Database
- **Image**: `mysql:8.0`
- **Port**: 3306
- **Storage**: 10Gi persistent volume
- **Database**: `wordpress`
- **User**: `wordpress`

## File Structure

```
├── Dockerfile                    # Java API image
├── Dockerfile.wordpress          # WordPress image
├── k8s/
│   ├── base/
│   │   ├── deployment.yaml       # Java API deployment
│   │   ├── service.yaml          # Java API service
│   │   ├── wordpress-deployment.yaml
│   │   ├── wordpress-service.yaml
│   │   ├── mysql-deployment.yaml
│   │   ├── mysql-service.yaml
│   │   ├── mysql-pvc.yaml        # Persistent storage
│   │   ├── mysql-secret.yaml     # Database credentials
│   │   ├── ingress.yaml          # Traffic routing
│   │   └── kustomization.yaml
│   └── overlays/dev/
│       └── kustomization.yaml    # Environment-specific config
├── charts/
│   ├── myapp/                    # Java API Helm chart
│   └── wordpress/                # WordPress Helm chart
└── .github/workflows/ci-cd.yml  # Updated for both services
```

## Setup Instructions

### 1. Repository Secrets
Add these secrets to your GitHub repository:
- `REGISTRY` → `docker.io`
- `REGISTRY_USERNAME` → Your Docker Hub username
- `REGISTRY_PASSWORD` → Your Docker Hub password/token

### 2. Local Development
```bash
# Build Java API
mvn clean package
docker build -t cloudwave-api .

# Build WordPress
docker build -f Dockerfile.wordpress -t cloudwave-wordpress .
```

### 3. Kubernetes Deployment

#### Option A: Using Kustomize (Recommended)
```bash
# Deploy to dev environment
kubectl apply -k k8s/overlays/dev/
```

#### Option B: Using Helm Charts
```bash
# Deploy Java API
helm install cloudwave-api charts/myapp/

# Deploy WordPress
helm install wordpress charts/wordpress/
```

### 4. Access Applications

Add these entries to your `/etc/hosts` (Linux/Mac) or `C:\Windows\System32\drivers\etc\hosts` (Windows):
```
127.0.0.1 api.cloudwave.local
127.0.0.1 wordpress.cloudwave.local
```

Then access:
- **Java API**: http://api.cloudwave.local
- **WordPress**: http://wordpress.cloudwave.local

## CI/CD Pipeline

The GitHub Actions workflow now:
1. **Builds Java API** with Maven
2. **Runs tests** and static analysis (SpotBugs)
3. **Builds both Docker images**:
   - `cloudwave-api:${GITHUB_SHA}`
   - `cloudwave-wordpress:${GITHUB_SHA}`
4. **Scans both images** with Trivy
5. **Updates Kustomize overlays** with new image tags
6. **Commits changes** for ArgoCD to sync

## Database Configuration

### Default Credentials (Change in Production!)
- **Root Password**: `rootpassword`
- **WordPress DB**: `wordpress`
- **WordPress User**: `wordpress`
- **WordPress Password**: `wordpresspass`

### Updating Secrets
```bash
# Create new secret values (base64 encoded)
echo -n "your-new-password" | base64

# Update k8s/base/mysql-secret.yaml with new values
```

## Monitoring & Health Checks

### Java API Health Check
```bash
curl http://api.cloudwave.local/health
```

### WordPress Health Check
```bash
curl http://wordpress.cloudwave.local/wp-admin/install.php
```

### Database Connection Test
```bash
kubectl exec -it deployment/mysql -n cloudwave -- mysql -u wordpress -p wordpress
```

## Troubleshooting

### Common Issues

1. **Images not pulling**: Check registry credentials
2. **Database connection failed**: Verify MySQL service is running
3. **Ingress not working**: Ensure ingress controller is installed
4. **Persistent volume issues**: Check storage class availability

### Useful Commands
```bash
# Check pod status
kubectl get pods -n cloudwave

# View logs
kubectl logs deployment/wordpress -n cloudwave
kubectl logs deployment/mysql -n cloudwave

# Port forward for local testing
kubectl port-forward svc/wordpress-svc 8080:80 -n cloudwave
kubectl port-forward svc/mysql-svc 3306:3306 -n cloudwave
```

## Production Considerations

1. **Security**: Update default passwords and use proper secrets management
2. **Storage**: Configure appropriate storage classes and backup strategies
3. **Scaling**: Adjust replica counts based on load requirements
4. **Monitoring**: Add proper monitoring and alerting
5. **SSL/TLS**: Configure HTTPS with proper certificates
6. **Resource Limits**: Fine-tune CPU and memory limits based on usage

## Next Steps

1. Configure proper domain names and SSL certificates
2. Set up monitoring with Prometheus/Grafana
3. Implement backup strategies for MySQL data
4. Add more comprehensive health checks
5. Configure horizontal pod autoscaling (HPA)