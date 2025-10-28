# Security Scanning Configuration

## Current Configuration (Testing Mode)

Both CI/CD pipelines are currently configured for **testing mode** where security scans won't block the pipeline:

### Trivy Image Scanning
- **Exit Code**: `0` (continue on vulnerabilities)
- **Continue on Error**: `true` (pipeline continues even if step fails)
- **Purpose**: Scan for OS and library vulnerabilities but don't block deployment

### SpotBugs Static Analysis (Full Pipeline Only)
- **Continue on Error**: `true` (pipeline continues even if issues found)
- **Purpose**: Find potential code issues but don't block deployment

## Production Configuration

For production environments, you should make security scans blocking:

### Enable Blocking Trivy Scans

**In `.github/workflows/ci-cd.yml`:**
```yaml
- name: Scan image with Trivy
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: ${{ steps.build-image.outputs.IMAGE }}
    format: "table"
    exit-code: "1"  # FAIL pipeline on high severity findings
    vuln-type: "os,library"
    severity: "CRITICAL,HIGH"  # Only fail on critical/high severity
  # Remove continue-on-error for production
```

**In `.github/workflows/ci-cd-simple.yml`:**
```yaml
- name: Scan image with Trivy
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: ${{ steps.build-image.outputs.IMAGE }}
    exit-code: "1"  # FAIL pipeline on vulnerabilities
    severity: "CRITICAL,HIGH"
  # Remove continue-on-error for production
```

### Enable Blocking SpotBugs

**In `.github/workflows/ci-cd.yml`:**
```yaml
- name: Run SpotBugs (static analysis)
  run: mvn com.github.spotbugs:spotbugs-maven-plugin:check
  # Remove continue-on-error and fallback command
```

## Severity Levels

### Trivy Severity Levels
- **CRITICAL**: Immediate action required
- **HIGH**: Should be fixed soon
- **MEDIUM**: Should be reviewed
- **LOW**: Minor issues
- **UNKNOWN**: Unclassified vulnerabilities

### Recommended Production Settings
```yaml
severity: "CRITICAL,HIGH"  # Block only on critical and high
# OR
severity: "CRITICAL"       # Block only on critical (more permissive)
```

## Advanced Trivy Configuration

### Ignore Specific Vulnerabilities
Create `.trivyignore` file in repository root:
```
# Ignore specific CVEs
CVE-2021-12345
CVE-2021-67890

# Ignore by package
pkg:maven/org.example/vulnerable-package
```

### Custom Trivy Configuration
```yaml
- name: Scan image with Trivy
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: ${{ steps.build-image.outputs.IMAGE }}
    format: "sarif"
    output: "trivy-results.sarif"
    exit-code: "1"
    vuln-type: "os,library"
    severity: "CRITICAL,HIGH"
    ignore-unfixed: true  # Ignore vulnerabilities without fixes
```

## Monitoring and Reporting

### Upload Scan Results
```yaml
- name: Upload Trivy scan results
  uses: github/codeql-action/upload-sarif@v2
  if: always()
  with:
    sarif_file: "trivy-results.sarif"
```

### Slack Notifications on Failures
```yaml
- name: Notify on security scan failure
  if: failure()
  uses: 8398a7/action-slack@v3
  with:
    status: failure
    text: "Security scan failed for CloudWave API"
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

## Migration Strategy

### Phase 1: Testing (Current)
- ✅ Scans run but don't block
- ✅ Visibility into vulnerabilities
- ✅ Team gets familiar with scan results

### Phase 2: Gradual Enforcement
- Block only CRITICAL vulnerabilities
- Monitor and fix issues
- Adjust thresholds based on findings

### Phase 3: Full Production
- Block CRITICAL and HIGH vulnerabilities
- Implement vulnerability management process
- Regular security reviews

## Best Practices

1. **Start Permissive**: Begin with non-blocking scans
2. **Monitor Results**: Review scan outputs regularly
3. **Fix Gradually**: Address vulnerabilities systematically
4. **Set Realistic Thresholds**: Balance security with development velocity
5. **Use Ignore Lists**: Document accepted risks in `.trivyignore`
6. **Regular Updates**: Keep base images and dependencies updated