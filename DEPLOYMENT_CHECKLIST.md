# 🚀 Wiz Exercise Deployment Checklist

## **Pre-Deployment Requirements**
- [ ] AWS CLI configured with admin permissions
- [ ] kubectl installed
- [ ] Terraform installed (v1.12+)
- [ ] Git repository cloned

## **Infrastructure Deployment**
```bash
cd terraform
terraform init
terraform apply -var="aws_region=us-east-1"
```

- [ ] Verify VPC created: `aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*wiz-exercise*"`
- [ ] Verify EKS cluster: `aws eks describe-cluster --name wiz-exercise-dev`
- [ ] Verify MongoDB VM: `aws ec2 describe-instances --filters "Name=tag:Name,Values=*wiz-exercise-dev-mongodb*"`

## **Kubernetes Configuration**
```bash
aws eks update-kubeconfig --region us-east-1 --name wiz-exercise-dev
kubectl get nodes
kubectl apply -f k8s/app/
kubectl create service loadbalancer wiz-todo-app --tcp=80:3000
```

- [ ] Wait for external IP: `kubectl get service wiz-todo-app -w`

## **Application Testing**
```bash
# Test health endpoint
LOAD_BALANCER_DNS=$(kubectl get service wiz-todo-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl http://$LOAD_BALANCER_DNS/health

# Test application
curl http://$LOAD_BALANCER_DNS/
```

## **Security Verification**
- [ ] RBAC vulnerability: `kubectl auth can-i --list --as=system:serviceaccount:default:wiz-todo-app-sa`
- [ ] MongoDB VM SSH access from 0.0.0.0/0
- [ ] Container vulnerabilities (Node.js 16.14.0 + Alpine 3.15)

## **Expected Results**
✅ **LoadBalancer DNS**: Working external access  
✅ **Health Check**: `{"status":"ok","message":"Wiz Demo App"}`  
✅ **RBAC Vulnerability**: Service account has cluster-admin  
✅ **MongoDB VM**: SSH accessible from anywhere  
✅ **Container Vulnerabilities**: Outdated Node.js and Alpine versions  

## **Troubleshooting**
If LoadBalancer shows "OutOfService":
1. Check health check is HTTP (not TCP) on the NodePort
2. Ensure ALB can reach EKS nodes on the NodePort
3. Verify security groups allow traffic

```bash
# Get NodePort
NODEPORT=$(kubectl get service wiz-todo-app -o jsonpath='{.spec.ports[0].nodePort}')
echo "NodePort: $NODEPORT"

# Test node health
kubectl get nodes -o wide
```