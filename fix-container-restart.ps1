# CloudWave API Container Restart Fix Script

Write-Host "🔧 CloudWave API Container Restart Fix" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

# Get current pod status
Write-Host "`n1. Current Pod Status:" -ForegroundColor Blue
kubectl get pods -n cloudwave -l app=cloudwave-api

# Get pod events to see what's failing
Write-Host "`n2. Pod Events (Last 10):" -ForegroundColor Blue
$podName = kubectl get pods -n cloudwave -l app=cloudwave-api -o jsonpath='{.items[0].metadata.name}' 2>$null
if ($podName) {
    kubectl describe pod $podName -n cloudwave | Select-String -Pattern "Events:" -A 20
} else {
    Write-Host "No pods found" -ForegroundColor Yellow
}

# Get container logs
Write-Host "`n3. Container Logs (Last 20 lines):" -ForegroundColor Blue
kubectl logs -n cloudwave -l app=cloudwave-api --tail=20 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Getting previous container logs..." -ForegroundColor Yellow
    kubectl logs -n cloudwave -l app=cloudwave-api --previous --tail=20 2>$null
}

# Check current image being used
Write-Host "`n4. Current Image Configuration:" -ForegroundColor Blue
kubectl get deployment cloudwave-api -n cloudwave -o jsonpath='{.spec.template.spec.containers[0].image}' 2>$null
Write-Host ""

# Check if image exists in Docker Hub
Write-Host "`n5. Checking Image Availability:" -ForegroundColor Blue
$currentImage = kubectl get deployment cloudwave-api -n cloudwave -o jsonpath='{.spec.template.spec.containers[0].image}' 2>$null
if ($currentImage) {
    Write-Host "Current image: $currentImage"
    Write-Host "Checking if image exists in Docker Hub..."
    
    # Try to get image info (this will fail if image doesn't exist)
    docker pull $currentImage 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Image exists and is accessible" -ForegroundColor Green
    } else {
        Write-Host "❌ Image not found or not accessible" -ForegroundColor Red
        Write-Host "💡 This is likely the cause of the container restart issue" -ForegroundColor Yellow
    }
}

# Provide fix recommendations
Write-Host "`n6. Fix Recommendations:" -ForegroundColor Blue

Write-Host "📋 To fix the container restart issue:" -ForegroundColor Yellow
Write-Host "1. Update YOUR_USERNAME in the following files with your actual Docker Hub username:"
Write-Host "   - k8s/base/deployment.yaml"
Write-Host "   - k8s/overlays/dev/kustomization.yaml"
Write-Host "   - charts/myapp/values.yaml"

Write-Host "`n2. Ensure your Docker Hub repository exists and is public:"
Write-Host "   - Go to https://hub.docker.com"
Write-Host "   - Check if 'cloudwave-api' repository exists"
Write-Host "   - Make sure it's public or configure image pull secrets"

Write-Host "`n3. Verify the image tag exists:"
Write-Host "   - Check what tag was pushed by your CI/CD pipeline"
Write-Host "   - Update kustomization.yaml with the correct tag"

Write-Host "`n4. Apply the fixes:"
Write-Host "   kubectl apply -k k8s/overlays/dev"

Write-Host "`n5. Monitor the deployment:"
Write-Host "   kubectl rollout status deployment/cloudwave-api -n cloudwave"

# Quick fix option
Write-Host "`n7. Quick Fix Options:" -ForegroundColor Blue
Write-Host "Option A - Use a working public image for testing:"
Write-Host "   kubectl set image deployment/cloudwave-api cloudwave-api=nginx:alpine -n cloudwave"

Write-Host "`nOption B - Scale down and back up:"
Write-Host "   kubectl scale deployment cloudwave-api --replicas=0 -n cloudwave"
Write-Host "   kubectl scale deployment cloudwave-api --replicas=1 -n cloudwave"

Write-Host "`nOption C - Delete and recreate:"
Write-Host "   kubectl delete deployment cloudwave-api -n cloudwave"
Write-Host "   kubectl apply -k k8s/overlays/dev"

Write-Host "`n🔍 For detailed troubleshooting, see: TROUBLESHOOTING_GUIDE.md" -ForegroundColor Cyan