# Setup Guide

## Prerequisites

1. **GitHub Repository**: Fork or create a new repository from this template
2. **Container Registry**: Access to GitHub Container Registry (GHCR) or Docker Hub
3. **Kubernetes Cluster**: A running Kubernetes cluster with ArgoCD installed
4. **Java 17**: For local development

## Required Repository Secrets

Configure these secrets in your GitHub repository settings:

```
REGISTRY=ghcr.io                    # or docker.io for Docker Hub
REGISTRY_USERNAME=YOUR_GITHUB_USERNAME
REGISTRY_PASSWORD=YOUR_GITHUB_PAT   # Personal Access Token with packages:write scope
```

## Configuration Steps

### 1. Update Repository References

Replace `YOUR_USERNAME` and `YOUR_REPO_NAME` in these files:
- `k8s/base/deployment.yaml`
- `k8s/overlays/dev/kustomization.yaml`
- `charts/myapp/values.yaml`
- `manifests/argocd/application.yaml`
- `manifests/argocd/application-helm.yaml`

### 2. ArgoCD Setup

Apply the ArgoCD application manifest:

```bash
# For Kustomize-based deployment
kubectl apply -f manifests/argocd/application.yaml

# OR for Helm-based deployment
kubectl apply -f manifests/argocd/application-helm.yaml
```

### 3. Local Development

```bash
# Build and test
mvn clean test package

# Run locally
java -jar target/devops-sample-app-0.0.1-SNAPSHOT.jar

# Test endpoints
curl http://localhost:8080/
curl http://localhost:8080/health
```

### 4. Docker Build

```bash
docker build -t devops-sample-app .
docker run -p 8080:8080 devops-sample-app
```

## Workflow Triggers

The CI/CD pipeline triggers on pushes to `main` or `master` branches and will:

1. Build and test the Java application
2. Run security scans (SpotBugs + Trivy)
3. Build and push Docker image
4. Update Kubernetes manifests
5. Commit changes for ArgoCD to sync

## Troubleshooting

- **Build failures**: Check Java version and Maven dependencies
- **Image push failures**: Verify registry credentials and permissions
- **ArgoCD sync issues**: Ensure repository URL and path are correct
- **Resource issues**: Adjust CPU/memory limits in deployment manifests