#!/bin/bash
# Install AWS Load Balancer Controller

set -e

echo "🚀 Installing AWS Load Balancer Controller..."

# Get cluster name and account ID
CLUSTER_NAME=$(kubectl config current-context | cut -d'/' -f2)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Cluster: $CLUSTER_NAME"
echo "Account: $ACCOUNT_ID"

# Download IAM policy
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json

# Create IAM policy (idempotent)
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json 2>/dev/null || echo "Policy already exists"

# Install eksctl if not present
if ! command -v eksctl &> /dev/null; then
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
    sudo mv /tmp/eksctl /usr/local/bin
fi

# Create service account with IAM role
eksctl create iamserviceaccount \
    --cluster=$CLUSTER_NAME \
    --namespace=kube-system \
    --name=aws-load-balancer-controller \
    --role-name=AmazonEKSLoadBalancerControllerRole \
    --attach-policy-arn=arn:aws:iam::$ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy \
    --approve \
    --override-existing-serviceaccounts

# Install Helm if not present
if ! command -v helm &> /dev/null; then
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Add EKS Helm repository and install controller
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName=$CLUSTER_NAME \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller

# Wait for controller to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=aws-load-balancer-controller -n kube-system --timeout=300s

echo "✅ ALB Controller installed!"

# Clean up
rm -f iam_policy.json