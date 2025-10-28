# Security / DevSecOps Notes

- **Trivy** is used for container image scanning in the workflow. It checks OS packages and language libraries for vulnerabilities.
- **SpotBugs** is configured via Maven to run during the build and will fail the build if serious issues are found.
- **Secrets**: DO NOT commit any credentials. Use GitHub repository secrets:
  - `REGISTRY` (docker.io)
  - `REGISTRY_USERNAME` (your Docker Hub username)
  - `REGISTRY_PASSWORD` (your Docker Hub password or access token)
- Adjust the Trivy `exit-code` and severity thresholds to fit your risk tolerance.
- For more advanced scanning you can integrate:
  - SCA (Snyk / Dependabot / OSS Index)
  - Container hardening checks (CIS Benchmarks)
  - Infrastructure as code scanning (e.g., tfsec, kubeconform, kube-linter)
