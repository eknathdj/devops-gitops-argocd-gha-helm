
# CloudWave Multi-Service Platform - GitOps with ArgoCD + GitHub Actions

This repository demonstrates a GitOps workflow using **ArgoCD** (for deployment) and **GitHub Actions** (for CI/CD) with multiple services:
- **Java Spring Boot API** (CloudWave API)
- **WordPress** with MySQL database

The pipeline builds both applications, scans containers and code for security issues, pushes images to a container registry, updates the Kustomize overlay image tags and commits changes back so **ArgoCD** can pick up and deploy automatically.

**What's included**
- **Java Spring Boot API** (Maven-based) with health checks
- **WordPress** application with MySQL database
- **Two Dockerfiles**: `Dockerfile` (Java) and `Dockerfile.wordpress`
- **Kubernetes manifests** using **kustomize** (base + overlays/dev):
  - Java API deployment and service
  - WordPress deployment and service  
  - MySQL deployment, service, PVC, and secrets
  - Ingress for routing traffic to both services
- **Helm charts** for both applications (`charts/myapp/` and `charts/wordpress/`)
- **ArgoCD Application** manifest that points to the overlay path
- **GitHub Actions workflow** `.github/workflows/ci-cd.yml` that:
  - Builds Java app with Maven and runs tests
  - Runs static code analysis (SpotBugs via Maven)
  - Builds and pushes **both Docker images** to registry
  - Scans **both images** using Trivy security scanner
  - Updates `kustomization.yaml` with new image tags and commits changes
- **DevSecOps scanning** for both services (SpotBugs + Trivy) - configured in testing mode

> **NOTE:** No secrets are included. You must set repository secrets as documented below before running the workflow.

## Quickstart / Setup

1. Create repository in GitHub and push this scaffold.
2. Add the following repository secrets (example for Docker Hub):
   - `REGISTRY`  -> `docker.io`
   - `REGISTRY_USERNAME` -> your Docker Hub username
   - `REGISTRY_PASSWORD` -> your Docker Hub password or access token
   - `GITHUB_TOKEN` is provided automatically in Actions; workflows that push back use it.
3. Configure ArgoCD to connect to your Git server (or point ArgoCD to this repo) and create the ArgoCD Application using `manifests/argocd/application.yaml` OR let ArgoCD track this repo automatically.
4. When workflow runs it will:
   - Build & push Java API image: `{{ registry }}/<owner>/cloudwave-api:<sha>`
   - Build & push WordPress image: `{{ registry }}/<owner>/cloudwave-wordpress:<sha>`
   - Update `k8s/overlays/dev/kustomization.yaml` with both new image tags and push the commit
   - ArgoCD will detect the changes and deploy both services

## Files of interest

- `Dockerfile` - builds Java (OpenJDK) image
- `Dockerfile.wordpress` - builds WordPress image
- `pom.xml` - Maven project for Java API
- `src/main/java/...` - CloudWave API Spring Boot app
- `k8s/base/*` and `k8s/overlays/dev/*` - kustomize manifests for both services
- `charts/myapp/` - Helm chart for Java API
- `charts/wordpress/` - Helm chart for WordPress
- `.github/workflows/ci-cd.yml` - GitHub Actions pipeline (builds both services)
- `manifests/argocd/application.yaml` - ArgoCD Application manifest
- `MULTI_SERVICE_SETUP.md` - Detailed multi-service setup guide
- `ARGOCD_SETUP_GUIDE.md` - Complete ArgoCD setup and usage guide
- `verify-deployment.ps1` - PowerShell script to verify deployment status

## How the GitOps flow works in this example

1. Developer pushes code to GitHub OR triggers via repository dispatch.
2. GitHub Actions builds the app, runs scans, builds and pushes the image to registry.
3. The workflow updates the kustomize overlay image tag and commits to the repo.
4. ArgoCD (configured to watch `/k8s/overlays/dev`) detects the change and syncs the cluster automatically.

### Trigger Options
- **Push to main/master**: Automatic trigger on code changes
- **Repository Dispatch**: Remote API trigger (see `REPOSITORY_DISPATCH_GUIDE.md`)


## Helm chart
This repo contains a Helm chart at `charts/myapp` for CloudWave API. The CI updates `charts/myapp/values.yaml` with the image tag so ArgoCD (or `helm upgrade`) can pick up new versions.

## Multi-Service Architecture

This setup now includes:

### Services
- **Java API**: `http://api.cloudwave.local` (Spring Boot on port 8080)
- **WordPress**: `http://wordpress.cloudwave.local` (WordPress on port 80)
- **MySQL**: Internal database service for WordPress

### Access URLs
Add to your `/etc/hosts` or `C:\Windows\System32\drivers\etc\hosts`:
```
127.0.0.1 api.cloudwave.local
127.0.0.1 wordpress.cloudwave.local
```

For detailed setup instructions, see `MULTI_SERVICE_SETUP.md`.