#!/bin/bash
# kubectl Demonstration Script for Wiz Interview
# This script demonstrates various kubectl commands to show the vulnerable environment

set -e

echo "🔍 Wiz Security Demo - kubectl Verification Commands"
echo "=================================================="

# Check cluster connection
echo ""
echo "📊 1. Cluster Status and Nodes:"
kubectl get nodes -o wide

# Check application pods
echo ""
echo "🚀 2. Application Pods Status:"
kubectl get pods -n wiz -o wide

# Check service account permissions (intentionally over-privileged)
echo ""
echo "⚠️  3. Service Account Permissions (VULNERABILITY - Cluster Admin):"
kubectl describe clusterrolebinding wiz-todo-app-admin

# Check services and load balancer
echo ""
echo "🌐 4. Services and Load Balancer:"
kubectl get services -n wiz

# Check ingress (if ALB controller is installed)
echo ""
echo "🔗 5. Ingress Configuration:"
kubectl get ingress -n wiz 2>/dev/null || echo "No ingress found (ALB controller not installed)"

# Check ConfigMap with MongoDB credentials (VULNERABILITY)
echo ""
echo "🔐 6. ConfigMap with Database Credentials (VULNERABILITY):"
kubectl get configmap wiz-todo-config -n wiz -o yaml | grep -A 5 "MONGO_URL"

# Verify wizexercise.txt file in container
echo ""
echo "📄 7. Verify wizexercise.txt file in container:"
POD_NAME=$(kubectl get pods -n wiz -l app=wiz-todo-app -o jsonpath='{.items[0].metadata.name}')
if [ ! -z "$POD_NAME" ]; then
    echo "Pod: $POD_NAME"
    kubectl exec -n wiz "$POD_NAME" -- cat /app/wizexercise.txt
else
    echo "No pods found"
fi

# Check application logs
echo ""
echo "📝 8. Application Logs (MongoDB Connection):"
if [ ! -z "$POD_NAME" ]; then
    kubectl logs -n wiz "$POD_NAME" --tail=10
else
    echo "No pods found"
fi

# Test application endpoints
echo ""
echo "🧪 9. Application Health Check:"
if [ ! -z "$POD_NAME" ]; then
    kubectl exec -n wiz "$POD_NAME" -- wget -qO- http://localhost:3000/health
else
    echo "No pods found"
fi

echo ""
echo "🔍 10. Application Vulnerabilities Info:"
if [ ! -z "$POD_NAME" ]; then
    kubectl exec -n wiz "$POD_NAME" -- wget -qO- http://localhost:3000/api/info
else
    echo "No pods found"
fi

echo ""
echo "✅ kubectl Demonstration Complete!"
echo ""
echo "🚨 Security Issues Demonstrated:"
echo "  - Cluster-admin service account privileges"
echo "  - Database credentials in ConfigMap"
echo "  - Application running with vulnerabilities"
echo "  - Load balancer exposing application to internet"