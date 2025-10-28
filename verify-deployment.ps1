# CloudWave API Deployment Verification Script (PowerShell)

Write-Host "🌊 CloudWave API Deployment Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Function to check if command exists
function Test-Command($cmdname) {
    return [bool](Get-Command -Name $cmdname -ErrorAction SilentlyContinue)
}

# Check prerequisites
Write-Host "`n1. Checking Prerequisites..." -ForegroundColor Blue

if (Test-Command kubectl) {
    Write-Host "✅ kubectl is installed" -ForegroundColor Green
} else {
    Write-Host "❌ kubectl is not installed" -ForegroundColor Red
    exit 1
}

if (Test-Command argocd) {
    Write-Host "✅ ArgoCD CLI is installed" -ForegroundColor Green
} else {
    Write-Host "⚠️  ArgoCD CLI is not installed (optional)" -ForegroundColor Yellow
}

# Check Kubernetes connection
Write-Host "`n2. Checking Kubernetes Connection..." -ForegroundColor Blue
try {
    $clusterInfo = kubectl cluster-info 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Connected to Kubernetes cluster" -ForegroundColor Green
        Write-Host ($clusterInfo | Select-Object -First 1)
    } else {
        throw "Connection failed"
    }
} catch {
    Write-Host "❌ Cannot connect to Kubernetes cluster" -ForegroundColor Red
    exit 1
}

# Check ArgoCD installation
Write-Host "`n3. Checking ArgoCD Installation..." -ForegroundColor Blue
try {
    kubectl get namespace argocd 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ ArgoCD namespace exists" -ForegroundColor Green
        
        # Check ArgoCD pods
        $pods = kubectl get pods -n argocd --no-headers 2>$null
        $totalPods = ($pods | Measure-Object).Count
        $runningPods = ($pods | Where-Object { $_ -match "Running" } | Measure-Object).Count
        
        Write-Host "📊 ArgoCD Pods: $runningPods/$totalPods running"
        
        if ($runningPods -eq $totalPods) {
            Write-Host "✅ All ArgoCD pods are running" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Some ArgoCD pods are not ready" -ForegroundColor Yellow
            kubectl get pods -n argocd
        }
    } else {
        throw "Namespace not found"
    }
} catch {
    Write-Host "❌ ArgoCD is not installed" -ForegroundColor Red
    Write-Host "💡 Install with: kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml" -ForegroundColor Yellow
    exit 1
}

# Check CloudWave namespace
Write-Host "`n4. Checking CloudWave Namespace..." -ForegroundColor Blue
try {
    kubectl get namespace cloudwave 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ CloudWave namespace exists" -ForegroundColor Green
    } else {
        throw "Namespace not found"
    }
} catch {
    Write-Host "⚠️  CloudWave namespace doesn't exist yet" -ForegroundColor Yellow
    Write-Host "💡 It will be created when ArgoCD deploys the application" -ForegroundColor Yellow
}

# Check ArgoCD Applications
Write-Host "`n5. Checking ArgoCD Applications..." -ForegroundColor Blue
try {
    $apps = kubectl get applications -n argocd --no-headers 2>$null | Select-String -Pattern "(cloudwave|devops-sample)"
    if ($apps) {
        Write-Host "✅ Found CloudWave applications in ArgoCD:" -ForegroundColor Green
        $apps | ForEach-Object { Write-Host $_.Line }
    } else {
        Write-Host "⚠️  No CloudWave applications found in ArgoCD" -ForegroundColor Yellow
        Write-Host "💡 Deploy with: kubectl apply -f manifests/argocd/application.yaml" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Could not check ArgoCD applications" -ForegroundColor Yellow
}

# Check CloudWave deployment
Write-Host "`n6. Checking CloudWave Deployment..." -ForegroundColor Blue
try {
    kubectl get deployment cloudwave-api -n cloudwave 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ CloudWave API deployment exists" -ForegroundColor Green
        
        # Check deployment status
        $replicas = kubectl get deployment cloudwave-api -n cloudwave -o jsonpath='{.status.replicas}' 2>$null
        $readyReplicas = kubectl get deployment cloudwave-api -n cloudwave -o jsonpath='{.status.readyReplicas}' 2>$null
        
        if (-not $readyReplicas) { $readyReplicas = "0" }
        Write-Host "📊 Deployment Status: $readyReplicas/$replicas replicas ready"
        
        # Check pods
        Write-Host "`n📋 Pod Status:"
        kubectl get pods -n cloudwave -l app=cloudwave-api
    } else {
        throw "Deployment not found"
    }
} catch {
    Write-Host "⚠️  CloudWave API deployment not found" -ForegroundColor Yellow
    Write-Host "💡 Check ArgoCD sync status" -ForegroundColor Yellow
}

# Check service
Write-Host "`n7. Checking CloudWave Service..." -ForegroundColor Blue
try {
    kubectl get service cloudwave-api-svc -n cloudwave 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ CloudWave API service exists" -ForegroundColor Green
        kubectl get service cloudwave-api-svc -n cloudwave
    } else {
        throw "Service not found"
    }
} catch {
    Write-Host "⚠️  CloudWave API service not found" -ForegroundColor Yellow
}

# Get ArgoCD admin password
Write-Host "`n8. ArgoCD Access Information..." -ForegroundColor Blue
try {
    kubectl get secret argocd-initial-admin-secret -n argocd 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $adminPassword = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>$null
        if ($adminPassword) {
            $decodedPassword = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($adminPassword))
            Write-Host "🔑 ArgoCD Admin Password: " -NoNewline
            Write-Host $decodedPassword -ForegroundColor Green
            Write-Host "🌐 Access ArgoCD UI:"
            Write-Host "   1. Run: " -NoNewline
            Write-Host "kubectl port-forward svc/argocd-server -n argocd 8080:443" -ForegroundColor Yellow
            Write-Host "   2. Open: " -NoNewline
            Write-Host "https://localhost:8080" -ForegroundColor Yellow
            Write-Host "   3. Login: admin / $decodedPassword"
        }
    } else {
        throw "Secret not found"
    }
} catch {
    Write-Host "⚠️  ArgoCD admin secret not found" -ForegroundColor Yellow
}

# Test application endpoint
Write-Host "`n9. Testing Application Endpoint..." -ForegroundColor Blue
try {
    $runningPods = kubectl get pods -n cloudwave -l app=cloudwave-api --no-headers 2>$null | Select-String -Pattern "Running"
    if ($runningPods) {
        Write-Host "💡 To test the application:"
        Write-Host "   1. Port forward: " -NoNewline
        Write-Host "kubectl port-forward svc/cloudwave-api-svc -n cloudwave 8080:80" -ForegroundColor Yellow
        Write-Host "   2. Test endpoint: " -NoNewline
        Write-Host "curl http://localhost:8080" -ForegroundColor Yellow
        Write-Host "   3. Health check: " -NoNewline
        Write-Host "curl http://localhost:8080/health" -ForegroundColor Yellow
    } else {
        Write-Host "⚠️  Application pods not running yet" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Could not check application status" -ForegroundColor Yellow
}

Write-Host "`n🎉 Verification Complete!" -ForegroundColor Green
Write-Host "📚 For detailed setup instructions, see: ARGOCD_SETUP_GUIDE.md" -ForegroundColor Cyan