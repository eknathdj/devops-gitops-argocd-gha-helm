
# CloudWave API - GitOps with ArgoCD + GitHub Actions (Java) + Helm

This repository is a scaffold to demonstrate a GitOps workflow using **ArgoCD** (for deployment) and **GitHub Actions** (for CI/CD).
It builds a simple Java (Spring Boot) app, scans the container and code for security issues, pushes the image to a container registry, updates the Kustomize overlay image tag and commits it back so **ArgoCD** can pick up and deploy the change.

**What's included**
- Simple Java Spring Boot application (Maven).
- Dockerfile to build a Java image.
- Kubernetes manifests (namespace, deployment, service) using **kustomize** (base + overlays/dev).
- ArgoCD Application manifest that points to the overlay path.
- GitHub Actions workflow `.github/workflows/ci-cd.yml` that:
  - Builds Java app with Maven.
  - Runs static code analysis (SpotBugs via Maven).
  - Builds and pushes Docker image to Docker Hub (or other registry).
  - Scans the built image using Trivy.
  - Updates `kustomization.yaml` in overlays/dev to set the new image tag and commits the change (so ArgoCD will sync).
- DevSecOps scanning steps example (SpotBugs + Trivy) - configured in testing mode (non-blocking).

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
   - Build & push image: `{{ registry }}/<owner>/cloudwave-api:<sha>`
   - Update `k8s/overlays/dev/kustomization.yaml` `images` tag to the new tag and push the commit.
   - ArgoCD will detect the change and deploy.

## Files of interest

- `Dockerfile` - builds Java (OpenJDK) image
- `pom.xml` - Maven project
- `src/main/java/...` - CloudWave API Spring Boot app
- `k8s/base/*` and `k8s/overlays/dev/*` - kustomize manifests
- `.github/workflows/ci-cd.yml` - GitHub Actions pipeline
- `manifests/argocd/application.yaml` - ArgoCD Application manifest
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
