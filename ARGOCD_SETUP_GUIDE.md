# ArgoCD Setup and Usage Guide

## 🚀 How ArgoCD Works in This Setup

ArgoCD implements **GitOps** - it continuously monitors your Git repository and automatically deploys changes to your Kubernetes cluster.

### The GitOps Flow:
1. **Code Push** → GitHub Actions builds and pushes Docker image
2. **Manifest Update** → Pipeline updates `k8s/overlays/dev/kustomization.yaml` with new image tag
3. **Git Commit** → New image tag is committed back to repository
4. **ArgoCD Sync** → ArgoCD detects the change and deploys to Kubernetes
5. **Application Running** → Your CloudWave API is updated in the cluster

## 📋 Prerequisites

### 1. Kubernetes Cluster
You need a running Kubernetes cluster with ArgoCD installed:
- **Local**: minikube, kind, k3s, Docker Desktop
- **Cloud**: EKS, GKE, AKS
- **On-premise**: Any Kubernetes distribution

### 2. ArgoCD Installation
If ArgoCD isn't installed yet:

```bash
# Create ArgoCD namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

## 🔧 ArgoCD Setup Steps

### Step 1: Access ArgoCD UI

#### Option A: Port Forward (Easiest)
```bash
# Forward ArgoCD server port
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Access at: https://localhost:8080
# (Accept the self-signed certificate warning)
```

#### Option B: LoadBalancer (Cloud)
```bash
# Change service type to LoadBalancer
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Get external IP
kubectl get svc argocd-server -n argocd
```

#### Option C: Ingress (Production)
```yaml
# argocd-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "GRPC"
spec:
  rules:
  - host: argocd.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 443
```

### Step 2: Get ArgoCD Admin Password

```bash
# Get the initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

# Login credentials:
# Username: admin
# Password: (output from above command)
```

### Step 3: Login to ArgoCD

#### Via Web UI:
1. Open https://localhost:8080 (or your ArgoCD URL)
2. Username: `admin`
3. Password: (from step 2)

#### Via CLI:
```bash
# Install ArgoCD CLI
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd

# Login via CLI
argocd login localhost:8080
# Username: admin
# Password: (from step 2)
```

## 🎯 Deploy CloudWave API

### Method 1: Using Kustomize (Recommended)

```bash
# Apply the ArgoCD Application manifest
kubectl apply -f manifests/argocd/application.yaml
```

This creates an ArgoCD Application that:
- **Monitors**: Your repository's `k8s/overlays/dev` path
- **Syncs**: Automatically when changes are detected
- **Deploys**: To the `cloudwave` namespace

### Method 2: Using Helm

```bash
# Apply the Helm-based ArgoCD Application
kubectl apply -f manifests/argocd/application-helm.yaml
```

This uses the Helm chart in `charts/myapp/`.

### Method 3: Via ArgoCD UI

1. **Login** to ArgoCD UI
2. **Click** "NEW APP"
3. **Fill in**:
   - **Application Name**: `cloudwave-api`
   - **Project**: `default`
   - **Sync Policy**: `Automatic`
   - **Repository URL**: `https://github.com/YOUR_USERNAME/YOUR_REPO`
   - **Revision**: `HEAD`
   - **Path**: `k8s/overlays/dev`
   - **Cluster URL**: `https://kubernetes.default.svc`
   - **Namespace**: `cloudwave`
4. **Click** "CREATE"

## 📊 Monitoring Your Application

### ArgoCD Web UI Features:

#### 1. Application Overview
- **Sync Status**: Shows if app is in sync with Git
- **Health Status**: Shows if Kubernetes resources are healthy
- **Last Sync**: When the last deployment happened

#### 2. Resource Tree View
- **Visual representation** of all Kubernetes resources
- **Real-time status** of pods, services, deployments
- **Click on resources** to see details and logs

#### 3. Sync Operations
- **Manual Sync**: Force immediate deployment
- **Refresh**: Check for Git changes
- **Hard Refresh**: Ignore cache and re-read from Git

#### 4. Application Logs
- **View logs** from all pods
- **Filter by container** or time range
- **Real-time streaming**

### CLI Monitoring:

```bash
# List all applications
argocd app list

# Get application details
argocd app get cloudwave-api

# View application logs
argocd app logs cloudwave-api

# Sync application manually
argocd app sync cloudwave-api

# Watch application status
argocd app wait cloudwave-api
```

## 🔍 Troubleshooting Common Issues

### 1. Application Not Syncing
```bash
# Check if ArgoCD can access your repository
argocd repo list

# Add repository if needed (for private repos)
argocd repo add https://github.com/YOUR_USERNAME/YOUR_REPO --username YOUR_USERNAME --password YOUR_TOKEN
```

### 2. Namespace Issues
```bash
# Create namespace if it doesn't exist
kubectl create namespace cloudwave
```

### 3. Image Pull Issues
```bash
# Check if image exists in Docker Hub
docker pull docker.io/YOUR_USERNAME/cloudwave-api:latest

# Check pod events
kubectl describe pod -n cloudwave -l app=cloudwave-api
```

### 4. Sync Errors
```bash
# View detailed sync status
argocd app get cloudwave-api --show-operation

# Check ArgoCD server logs
kubectl logs -n argocd deployment/argocd-server
```

## 🎛️ ArgoCD Configuration

### Enable Auto-Sync
```yaml
# In your application manifest
spec:
  syncPolicy:
    automated:
      prune: true      # Remove resources not in Git
      selfHeal: true   # Correct drift automatically
```

### Sync Windows (Optional)
```yaml
# Only sync during specific times
spec:
  syncPolicy:
    syncOptions:
    - CreateNamespace=true
    syncWindows:
    - kind: allow
      schedule: "0 9 * * 1-5"  # Weekdays 9 AM
      duration: 8h
```

## 📈 Best Practices

### 1. Repository Structure
- ✅ Keep manifests in dedicated directories
- ✅ Use overlays for different environments
- ✅ Version your Helm charts

### 2. Security
- 🔒 Use private repositories for sensitive configs
- 🔒 Implement RBAC for ArgoCD access
- 🔒 Use sealed secrets for sensitive data

### 3. Monitoring
- 📊 Set up alerts for sync failures
- 📊 Monitor application health
- 📊 Track deployment frequency

## 🚀 Next Steps

1. **Access ArgoCD UI** and explore your application
2. **Make a code change** and watch GitOps in action
3. **Set up monitoring** and alerting
4. **Configure multiple environments** (staging, production)
5. **Implement progressive delivery** with Argo Rollouts

Your CloudWave API is now fully GitOps-enabled! 🌊