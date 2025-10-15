#!/bin/bash

# Wiz Assignment Validation Script
echo "🎯 Wiz Assignment Validation"
echo "============================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
        return 1
    fi
}

echo ""
echo "1️⃣ CORE REQUIREMENTS"

# Check wizexercise.txt
if [ -f "app/wizexercise.txt" ] && [ "$(cat app/wizexercise.txt)" = "Devon Diffie" ]; then
    print_status 0 "wizexercise.txt exists with correct content"
else
    print_status 1 "wizexercise.txt missing or incorrect"
fi

# Check AWS
if aws sts get-caller-identity &> /dev/null; then
    print_status 0 "AWS credentials configured"
else
    print_status 1 "AWS credentials not configured"
    exit 1
fi

# Check kubectl
if kubectl cluster-info &> /dev/null; then
    print_status 0 "kubectl connected to cluster"
else
    print_status 1 "kubectl not connected"
    echo "Run: aws eks update-kubeconfig --region us-east-1 --name wiz-exercise-dev"
    exit 1
fi

echo ""
echo "2️⃣ INFRASTRUCTURE"

# EKS cluster
EKS_STATUS=$(aws eks describe-cluster --name wiz-exercise-dev --query 'cluster.status' --output text 2>/dev/null)
if [ "$EKS_STATUS" = "ACTIVE" ]; then
    print_status 0 "EKS cluster active"
else
    print_status 1 "EKS cluster not active"
fi

# MongoDB VM
VM_STATE=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=wiz-exercise-dev-mongodb" --query 'Reservations[0].Instances[0].State.Name' --output text 2>/dev/null)
if [ "$VM_STATE" = "running" ]; then
    print_status 0 "MongoDB VM running"
else
    print_status 1 "MongoDB VM not running"
fi

echo ""
echo "3️⃣ APPLICATION"

# Check pods
POD_COUNT=$(kubectl get pods -l app=wiz-todo-app --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
if [ "$POD_COUNT" -gt 0 ]; then
    print_status 0 "Application pods running ($POD_COUNT)"
else
    print_status 1 "No application pods running"
fi

# Check wizexercise.txt in container
POD_NAME=$(kubectl get pods -l app=wiz-todo-app --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$POD_NAME" ]; then
    FILE_CONTENT=$(kubectl exec "$POD_NAME" -- cat /app/wizexercise.txt 2>/dev/null)
    if [ "$FILE_CONTENT" = "Devon Diffie" ]; then
        print_status 0 "wizexercise.txt accessible in container"
    else
        print_status 1 "wizexercise.txt in container incorrect"
    fi
fi

# Check LoadBalancer
LOAD_BALANCER_URL=$(kubectl get service wiz-todo-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
if [ -n "$LOAD_BALANCER_URL" ] && [ "$LOAD_BALANCER_URL" != "null" ]; then
    print_status 0 "LoadBalancer available"
    
    # Test health endpoint
    if curl -f -s "http://$LOAD_BALANCER_URL/health" > /dev/null 2>&1; then
        print_status 0 "Health endpoint responding"
        HEALTH_RESPONSE=$(curl -s "http://$LOAD_BALANCER_URL/health" 2>/dev/null)
        echo "   Response: $HEALTH_RESPONSE"
    else
        print_status 1 "Health endpoint not responding"
    fi
else
    print_status 1 "LoadBalancer not available"
fi

echo ""
echo "4️⃣ SECURITY VULNERABILITIES"

# Public S3 bucket
BUCKET_NAME=$(aws s3 ls | grep wiz-exercise | awk '{print $3}' 2>/dev/null)
if [ -n "$BUCKET_NAME" ] && aws s3 ls "s3://$BUCKET_NAME" --no-sign-request &>/dev/null; then
    print_status 0 "Public S3 bucket accessible"
else
    print_status 1 "S3 bucket not publicly accessible"
fi

# Kubernetes over-privileges
if kubectl auth can-i create nodes --as=system:serviceaccount:default:wiz-todo-app-sa 2>/dev/null | grep -q "yes"; then
    print_status 0 "Service account has cluster-admin privileges"
else
    print_status 1 "Service account not over-privileged"
fi

echo ""
echo "5️⃣ CI/CD WORKFLOWS"

[ -f ".github/workflows/terraform-apply.yml" ] && print_status 0 "Terraform workflow exists" || print_status 1 "Terraform workflow missing"
[ -f ".github/workflows/container-security.yml" ] && print_status 0 "Container security workflow exists" || print_status 1 "Container security workflow missing"
[ -f ".github/workflows/k8s-deploy.yml" ] && print_status 0 "Kubernetes workflow exists" || print_status 1 "Kubernetes workflow missing"

echo ""
echo "📊 SUMMARY"
echo "=========="
echo "Application: http://$LOAD_BALANCER_URL"
echo "Health Check: http://$LOAD_BALANCER_URL/health"
echo "Public S3: $BUCKET_NAME"
echo ""
echo "🎯 Demo Commands:"
echo "kubectl exec $POD_NAME -- cat /app/wizexercise.txt"
echo "curl http://$LOAD_BALANCER_URL/health"
echo "aws s3 ls s3://$BUCKET_NAME --no-sign-request"
echo ""
echo "✅ Assignment validation complete!"