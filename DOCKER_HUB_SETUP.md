# Docker Hub Configuration Guide

## Required Repository Secrets

Configure these secrets in your GitHub repository settings (Settings → Secrets and variables → Actions):

```
REGISTRY=docker.io
REGISTRY_USERNAME=your-dockerhub-username
REGISTRY_PASSWORD=your-dockerhub-password-or-token
```

## Docker Hub Access Token (Recommended)

Instead of using your Docker Hub password, create an access token:

1. Log in to [Docker Hub](https://hub.docker.com/)
2. Go to Account Settings → Security
3. Click "New Access Token"
4. Give it a name (e.g., "GitHub Actions")
5. Select permissions: **Read, Write, Delete**
6. Copy the generated token and use it as `REGISTRY_PASSWORD`

## Repository Configuration

Make sure to update these placeholders in your files:

### In k8s/base/deployment.yaml:
```yaml
image: docker.io/YOUR_USERNAME/cloudwave-api:latest
```

### In k8s/overlays/dev/kustomization.yaml:
```yaml
images:
  - name: docker.io/YOUR_USERNAME/cloudwave-api
```

### In charts/myapp/values.yaml:
```yaml
image:
  repository: docker.io/YOUR_USERNAME/cloudwave-api
```

Replace `YOUR_USERNAME` with your actual Docker Hub username.

## Docker Hub Repository

The workflow will automatically create the repository `cloudwave-api` in your Docker Hub account when it first pushes an image.

## Image Naming Convention

Images will be pushed as:
- `docker.io/your-username/cloudwave-api:commit-sha`
- Example: `docker.io/johndoe/cloudwave-api:a1b2c3d4`

## Troubleshooting

- **Authentication failed**: Check your username and password/token
- **Repository not found**: The repository will be created automatically on first push
- **Permission denied**: Ensure your access token has Write permissions
- **Rate limiting**: Docker Hub has pull/push rate limits for free accounts