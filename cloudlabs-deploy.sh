#!/bin/bash

echo "🚀 CloudLabs Deployment Script for Wiz Interview"
echo "================================================"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}1. Cloning repository...${NC}"
# git clone https://github.com/YOUR-USERNAME/Wiz_Homework.git
# cd Wiz_Homework

echo -e "${YELLOW}2. Deploying infrastructure with Terraform...${NC}"
cd terraform
terraform init
terraform apply -auto-approve

echo -e "${YELLOW}3. Configuring kubectl...${NC}"
aws eks update-kubeconfig --region us-east-1 --name wiz-exercise-dev

echo -e "${YELLOW}4. Deploying application to Kubernetes...${NC}"
cd ..
kubectl apply -f k8s/app/
kubectl create service loadbalancer wiz-todo-app --tcp=80:3000

echo -e "${YELLOW}5. Waiting for LoadBalancer to be ready...${NC}"
echo "This may take 2-3 minutes..."
kubectl wait --for=condition=ready pod -l app=wiz-todo-app --timeout=300s

echo -e "${YELLOW}6. Getting application URL...${NC}"
LOAD_BALANCER_URL=$(kubectl get service wiz-todo-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo -e "${GREEN}Application URL: http://$LOAD_BALANCER_URL${NC}"

echo -e "${YELLOW}7. Running validation tests...${NC}"
./validate-assignment.sh

echo -e "${GREEN}🎉 Deployment complete!${NC}"
echo ""
echo "Demo commands:"
echo "curl http://$LOAD_BALANCER_URL/health"
echo "kubectl exec \$(kubectl get pods -l app=wiz-todo-app -o jsonpath='{.items[0].metadata.name}') -- cat /app/wizexercise.txt"
echo "kubectl auth can-i --list --as=system:serviceaccount:default:wiz-todo-app-sa"