#!/bin/bash

# Simple Kubernetes deployment script
# Deploys the Todo app to Kubernetes cluster

set -e

echo "Deploying Wiz Todo App to Kubernetes..."

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    echo "Error: kubectl not configured"
    echo "Run: aws eks update-kubeconfig --region us-east-1 --name wiz-exercise-dev"
    exit 1
fi

echo "✓ kubectl configured"

# Deploy all manifests
echo "Deploying application..."
kubectl apply -f app/

# Wait for deployment
echo "Waiting for pods to start..."
kubectl rollout status deployment/wiz-todo-app --timeout=300s

# Show status
echo ""
echo "Deployment Status:"
kubectl get pods -l app=wiz-todo-app
kubectl get svc wiz-todo-app-service
kubectl get ingress wiz-todo-app-ingress

# Get ALB DNS
ALB_DNS=$(kubectl get ingress wiz-todo-app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Not ready yet")
echo ""
echo "Application URL: http://$ALB_DNS"
echo ""
echo "Test commands:"
echo "  kubectl get pods"
echo "  kubectl logs -l app=wiz-todo-app"
echo "  curl http://$ALB_DNS/health"