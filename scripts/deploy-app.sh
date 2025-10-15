#!/bin/bash
# Deploy Wiz Todo App to EKS
# This script deploys the application after Terraform infrastructure is ready

set -e

echo "🚀 Starting Wiz Todo App deployment..."

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Get Terraform outputs
cd "$PROJECT_ROOT/terraform"
MONGO_IP=$(terraform output -raw mongodb_private_ip)
CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
cd "$PROJECT_ROOT"

echo "📊 Infrastructure details:"
echo "  MongoDB Private IP: $MONGO_IP"
echo "  EKS Cluster: $CLUSTER_NAME"

# Configure kubectl
echo "🔧 Configuring kubectl..."
aws eks update-kubeconfig --region us-east-1 --name "$CLUSTER_NAME"

# Test kubectl connection
echo "🧪 Testing kubectl connection..."
kubectl get nodes

# Update ConfigMap with real MongoDB IP
echo "📝 Updating ConfigMap with MongoDB IP..."
sed -i "s/MONGO_PRIVATE_IP/$MONGO_IP/g" k8s/03-configmap.yaml

# Build and tag container image
echo "🐳 Building container image..."
cd "$PROJECT_ROOT/app"
docker build -t wiz-todo-app:latest .
cd "$PROJECT_ROOT"

# Create ECR repository if it doesn't exist
echo "📦 Setting up ECR repository..."
aws ecr describe-repositories --repository-names wiz-exercise-dev-app 2>/dev/null || \
  aws ecr create-repository --repository-name wiz-exercise-dev-app

# Get ECR login and push image
echo "📤 Pushing image to ECR..."
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
IMAGE_URI="$ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/wiz-exercise-dev-app:latest"

docker tag wiz-todo-app:latest "$IMAGE_URI"
docker push "$IMAGE_URI"

# Update deployment with image URI
echo "📝 Updating deployment manifest..."
sed -i "s|CONTAINER_IMAGE_URI|$IMAGE_URI|g" k8s/04-deployment.yaml

# Deploy to Kubernetes
echo "🚀 Deploying to Kubernetes..."
kubectl apply -f k8s/01-namespace.yaml
kubectl apply -f k8s/02-rbac.yaml
kubectl apply -f k8s/03-configmap.yaml
kubectl apply -f k8s/04-deployment.yaml
kubectl apply -f k8s/05-service.yaml

# Wait for deployment to be ready
echo "⏳ Waiting for deployment to be ready..."
kubectl rollout status deployment/wiz-todo-app -n wiz --timeout=300s

# Show deployment status
echo "📊 Deployment status:"
kubectl get pods -n wiz
kubectl get services -n wiz

# Test the application
echo "🧪 Testing application..."
POD_NAME=$(kubectl get pods -n wiz -l app=wiz-todo-app -o jsonpath='{.items[0].metadata.name}')

echo "📄 Verifying wizexercise.txt file:"
kubectl exec -n wiz "$POD_NAME" -- cat /app/wizexercise.txt

echo "🏥 Testing health endpoint:"
kubectl exec -n wiz "$POD_NAME" -- wget -qO- http://localhost:3000/health

echo "📊 Testing app info endpoint:"
kubectl exec -n wiz "$POD_NAME" -- wget -qO- http://localhost:3000/api/info

echo "✅ Application deployment complete!"
echo ""
echo "Next steps:"
echo "1. Install AWS Load Balancer Controller for ALB"
echo "2. Apply ingress manifest"
echo "3. Test end-to-end connectivity"