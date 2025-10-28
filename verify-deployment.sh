#!/bin/bash

# CloudWave API Deployment Verification Script

echo "🌊 CloudWave API Deployment Verification"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo -e "\n${BLUE}1. Checking Prerequisites...${NC}"

if command_exists kubectl; then
    echo -e "✅ kubectl is installed"
else
    echo -e "❌ kubectl is not installed"
    exit 1
fi

if command_exists argocd; then
    echo -e "✅ ArgoCD CLI is installed"
else
    echo -e "⚠️  ArgoCD CLI is not installed (optional)"
fi

# Check Kubernetes connection
echo -e "\n${BLUE}2. Checking Kubernetes Connection...${NC}"
if kubectl cluster-info >/dev/null 2>&1; then
    echo -e "✅ Connected to Kubernetes cluster"
    kubectl cluster-info | head -1
else
    echo -e "❌ Cannot connect to Kubernetes cluster"
    exit 1
fi

# Check ArgoCD installation
echo -e "\n${BLUE}3. Checking ArgoCD Installation...${NC}"
if kubectl get namespace argocd >/dev/null 2>&1; then
    echo -e "✅ ArgoCD namespace exists"
    
    # Check ArgoCD pods
    ARGOCD_PODS=$(kubectl get pods -n argocd --no-headers | wc -l)
    READY_PODS=$(kubectl get pods -n argocd --no-headers | grep "Running" | wc -l)
    echo -e "📊 ArgoCD Pods: ${READY_PODS}/${ARGOCD_PODS} running"
    
    if [ "$READY_PODS" -eq "$ARGOCD_PODS" ]; then
        echo -e "✅ All ArgoCD pods are running"
    else
        echo -e "⚠️  Some ArgoCD pods are not ready"
        kubectl get pods -n argocd
    fi
else
    echo -e "❌ ArgoCD is not installed"
    echo -e "💡 Install with: kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
    exit 1
fi

# Check CloudWave namespace
echo -e "\n${BLUE}4. Checking CloudWave Namespace...${NC}"
if kubectl get namespace cloudwave >/dev/null 2>&1; then
    echo -e "✅ CloudWave namespace exists"
else
    echo -e "⚠️  CloudWave namespace doesn't exist yet"
    echo -e "💡 It will be created when ArgoCD deploys the application"
fi

# Check ArgoCD Applications
echo -e "\n${BLUE}5. Checking ArgoCD Applications...${NC}"
APPS=$(kubectl get applications -n argocd --no-headers 2>/dev/null | grep -E "(cloudwave|devops-sample)" | wc -l)
if [ "$APPS" -gt 0 ]; then
    echo -e "✅ Found CloudWave applications in ArgoCD:"
    kubectl get applications -n argocd --no-headers 2>/dev/null | grep -E "(cloudwave|devops-sample)"
else
    echo -e "⚠️  No CloudWave applications found in ArgoCD"
    echo -e "💡 Deploy with: kubectl apply -f manifests/argocd/application.yaml"
fi

# Check CloudWave deployment
echo -e "\n${BLUE}6. Checking CloudWave Deployment...${NC}"
if kubectl get deployment cloudwave-api -n cloudwave >/dev/null 2>&1; then
    echo -e "✅ CloudWave API deployment exists"
    
    # Check deployment status
    REPLICAS=$(kubectl get deployment cloudwave-api -n cloudwave -o jsonpath='{.status.replicas}')
    READY_REPLICAS=$(kubectl get deployment cloudwave-api -n cloudwave -o jsonpath='{.status.readyReplicas}')
    echo -e "📊 Deployment Status: ${READY_REPLICAS:-0}/${REPLICAS} replicas ready"
    
    # Check pods
    echo -e "\n📋 Pod Status:"
    kubectl get pods -n cloudwave -l app=cloudwave-api
    
else
    echo -e "⚠️  CloudWave API deployment not found"
    echo -e "💡 Check ArgoCD sync status"
fi

# Check service
echo -e "\n${BLUE}7. Checking CloudWave Service...${NC}"
if kubectl get service cloudwave-api-svc -n cloudwave >/dev/null 2>&1; then
    echo -e "✅ CloudWave API service exists"
    kubectl get service cloudwave-api-svc -n cloudwave
else
    echo -e "⚠️  CloudWave API service not found"
fi

# Get ArgoCD admin password
echo -e "\n${BLUE}8. ArgoCD Access Information...${NC}"
if kubectl get secret argocd-initial-admin-secret -n argocd >/dev/null 2>&1; then
    ADMIN_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    echo -e "🔑 ArgoCD Admin Password: ${GREEN}${ADMIN_PASSWORD}${NC}"
    echo -e "🌐 Access ArgoCD UI:"
    echo -e "   1. Run: ${YELLOW}kubectl port-forward svc/argocd-server -n argocd 8080:443${NC}"
    echo -e "   2. Open: ${YELLOW}https://localhost:8080${NC}"
    echo -e "   3. Login: admin / ${ADMIN_PASSWORD}"
else
    echo -e "⚠️  ArgoCD admin secret not found"
fi

# Test application endpoint (if accessible)
echo -e "\n${BLUE}9. Testing Application Endpoint...${NC}"
if kubectl get pods -n cloudwave -l app=cloudwave-api --no-headers 2>/dev/null | grep -q "Running"; then
    echo -e "💡 To test the application:"
    echo -e "   1. Port forward: ${YELLOW}kubectl port-forward svc/cloudwave-api-svc -n cloudwave 8080:80${NC}"
    echo -e "   2. Test endpoint: ${YELLOW}curl http://localhost:8080${NC}"
    echo -e "   3. Health check: ${YELLOW}curl http://localhost:8080/health${NC}"
else
    echo -e "⚠️  Application pods not running yet"
fi

echo -e "\n${GREEN}🎉 Verification Complete!${NC}"
echo -e "📚 For detailed setup instructions, see: ARGOCD_SETUP_GUIDE.md"