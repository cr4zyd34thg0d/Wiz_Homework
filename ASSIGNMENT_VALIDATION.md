# 🎯 Assignment Requirements Validation

## **Core Requirements Checklist**

### ✅ **Required File: wizexercise.txt**
- [x] File exists at `app/wizexercise.txt`
- [x] Contains exactly: "Devon Diffie"
- [x] Included in Docker container build
- [x] Accessible in running pods

**Validation Commands:**
```bash
# Check file exists locally
cat app/wizexercise.txt

# Check file in running container
POD_NAME=$(kubectl get pods -l app=wiz-todo-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD_NAME -- cat /app/wizexercise.txt
```

### ✅ **Application Requirements**
- [x] Web application running and accessible
- [x] Health endpoint working
- [x] LoadBalancer providing external access
- [x] Application connects to MongoDB

**Validation Commands:**
```bash
# Get application URL
LOAD_BALANCER_URL=$(kubectl get service wiz-todo-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Application: http://$LOAD_BALANCER_URL"

# Test health endpoint
curl "http://$LOAD_BALANCER_URL/health"
# Expected: {"status":"ok","message":"Wiz Demo App"}

# Test main application
curl "http://$LOAD_BALANCER_URL/"
```

### ✅ **Infrastructure Requirements**
- [x] AWS cloud deployment
- [x] Kubernetes cluster (EKS)
- [x] Database (MongoDB on EC2)
- [x] Load balancer for external access
- [x] Infrastructure as Code (Terraform)

**Validation Commands:**
```bash
# Check EKS cluster
aws eks describe-cluster --name wiz-exercise-dev --query 'cluster.status'

# Check MongoDB VM
aws ec2 describe-instances --filters "Name=tag:Name,Values=wiz-exercise-dev-mongodb" --query 'Reservations[0].Instances[0].State.Name'

# Check VPC
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=wiz-exercise-dev-vpc" --query 'Vpcs[0].State'
```

### ✅ **Security Vulnerabilities (For Demo)**
- [x] Public S3 bucket
- [x] SSH access from anywhere
- [x] Over-privileged IAM roles
- [x] Outdated software versions
- [x] Container vulnerabilities
- [x] Kubernetes over-privileges

**Validation Commands:**
```bash
# Check public S3 bucket
BUCKET_NAME=$(aws s3 ls | grep wiz-exercise | awk '{print $3}')
aws s3 ls "s3://$BUCKET_NAME" --no-sign-request

# Check Kubernetes over-privileges
kubectl auth can-i --list --as=system:serviceaccount:default:wiz-todo-app-sa

# Check SSH security group
aws ec2 describe-security-groups --filters "Name=group-name,Values=wiz-exercise-dev-mongodb-sg" --query 'SecurityGroups[0].IpPermissions[?FromPort==`22`]'
```

### ✅ **CI/CD Pipeline**
- [x] GitHub Actions workflows
- [x] Terraform deployment pipeline
- [x] Container security scanning
- [x] Kubernetes deployment automation

**Validation Commands:**
```bash
# Check workflow files exist
ls -la .github/workflows/

# Verify workflows in GitHub (manual check)
# - terraform-apply.yml should run TfSec and deploy infrastructure
# - container-security.yml should run Trivy scanning
# - k8s-deploy.yml should deploy to Kubernetes
```

---

## **Complete End-to-End Test Script**

Run this to validate everything is working:

```bash
#!/bin/bash
echo "🎯 Wiz Assignment Validation Test"
echo "================================="

# Colors for output
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
echo "===================="

# Check wizexercise.txt file locally
if [ -f "app/wizexercise.txt" ] && [ "$(cat app/wizexercise.txt)" = "Devon Diffie" ]; then
    print_status 0 "wizexercise.txt file exists with correct content"
else
    print_status 1 "wizexercise.txt file missing or incorrect"
fi

# Check AWS connectivity
if aws sts get-caller-identity &> /dev/null; then
    print_status 0 "AWS credentials configured"
else
    print_status 1 "AWS credentials not configured"
    exit 1
fi

# Check kubectl connectivity
if kubectl cluster-info &> /dev/null; then
    print_status 0 "kubectl connected to cluster"
else
    print_status 1 "kubectl not connected - run: aws eks update-kubeconfig --region us-east-1 --name wiz-exercise-dev"
    exit 1
fi

echo ""
echo "2️⃣ INFRASTRUCTURE"
echo "================="

# Check EKS cluster
EKS_STATUS=$(aws eks describe-cluster --name wiz-exercise-dev --query 'cluster.status' --output text 2>/dev/null)
if [ "$EKS_STATUS" = "ACTIVE" ]; then
    print_status 0 "EKS cluster is active"
else
    print_status 1 "EKS cluster not active (status: $EKS_STATUS)"
fi

# Check MongoDB VM
VM_STATE=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=wiz-exercise-dev-mongodb" --query 'Reservations[0].Instances[0].State.Name' --output text 2>/dev/null)
if [ "$VM_STATE" = "running" ]; then
    print_status 0 "MongoDB VM is running"
else
    print_status 1 "MongoDB VM not running (state: $VM_STATE)"
fi

# Check VPC
VPC_STATE=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=wiz-exercise-dev-vpc" --query 'Vpcs[0].State' --output text 2>/dev/null)
if [ "$VPC_STATE" = "available" ]; then
    print_status 0 "VPC is available"
else
    print_status 1 "VPC not available"
fi

echo ""
echo "3️⃣ APPLICATION"
echo "=============="

# Check pods are running
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
        print_status 0 "wizexercise.txt accessible in container with correct content"
    else
        print_status 1 "wizexercise.txt in container incorrect: '$FILE_CONTENT'"
    fi
fi

# Check LoadBalancer
LOAD_BALANCER_URL=$(kubectl get service wiz-todo-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
if [ -n "$LOAD_BALANCER_URL" ] && [ "$LOAD_BALANCER_URL" != "null" ]; then
    print_status 0 "LoadBalancer URL available: http://$LOAD_BALANCER_URL"
    
    # Test health endpoint
    if curl -f -s "http://$LOAD_BALANCER_URL/health" > /dev/null 2>&1; then
        print_status 0 "Health endpoint responding"
        
        # Show health response
        HEALTH_RESPONSE=$(curl -s "http://$LOAD_BALANCER_URL/health" 2>/dev/null)
        echo "   Health response: $HEALTH_RESPONSE"
    else
        print_status 1 "Health endpoint not responding"
    fi
else
    print_status 1 "LoadBalancer URL not available"
fi

echo ""
echo "4️⃣ SECURITY VULNERABILITIES"
echo "==========================="

# Check public S3 bucket
BUCKET_NAME=$(aws s3 ls | grep wiz-exercise | awk '{print $3}' 2>/dev/null)
if [ -n "$BUCKET_NAME" ]; then
    if aws s3 ls "s3://$BUCKET_NAME" --no-sign-request &>/dev/null; then
        print_status 0 "Public S3 bucket accessible: $BUCKET_NAME"
    else
        print_status 1 "S3 bucket not publicly accessible"
    fi
else
    print_status 1 "S3 bucket not found"
fi

# Check Kubernetes over-privileges
if kubectl auth can-i create nodes --as=system:serviceaccount:default:wiz-todo-app-sa 2>/dev/null | grep -q "yes"; then
    print_status 0 "Service account has excessive privileges (cluster-admin)"
else
    print_status 1 "Service account privileges not excessive"
fi

# Check MongoDB SSH access
MONGO_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=wiz-exercise-dev-mongodb" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text 2>/dev/null)
if [ -n "$MONGO_IP" ] && [ "$MONGO_IP" != "null" ]; then
    SSH_CIDR=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=wiz-exercise-dev-mongodb-sg" --query 'SecurityGroups[0].IpPermissions[?FromPort==`22`].IpRanges[0].CidrIp' --output text 2>/dev/null)
    if [ "$SSH_CIDR" = "0.0.0.0/0" ]; then
        print_status 0 "SSH open to world (0.0.0.0/0) - MongoDB IP: $MONGO_IP"
    else
        print_status 1 "SSH access restricted"
    fi
fi

echo ""
echo "5️⃣ CI/CD PIPELINE"
echo "================="

# Check workflow files
if [ -f ".github/workflows/terraform-apply.yml" ]; then
    print_status 0 "Terraform pipeline workflow exists"
else
    print_status 1 "Terraform pipeline workflow missing"
fi

if [ -f ".github/workflows/container-security.yml" ]; then
    print_status 0 "Container security workflow exists"
else
    print_status 1 "Container security workflow missing"
fi

if [ -f ".github/workflows/k8s-deploy.yml" ]; then
    print_status 0 "Kubernetes deployment workflow exists"
else
    print_status 1 "Kubernetes deployment workflow missing"
fi

echo ""
echo "📊 SUMMARY"
echo "=========="
echo "Application URL: http://$LOAD_BALANCER_URL"
echo "Health Check: http://$LOAD_BALANCER_URL/health"
echo "MongoDB VM IP: $MONGO_IP"
echo "Public S3 Bucket: $BUCKET_NAME"
echo ""
echo "🎯 Assignment validation complete!"
echo ""
echo "📋 Demo Commands:"
echo "kubectl exec $POD_NAME -- cat /app/wizexercise.txt"
echo "curl http://$LOAD_BALANCER_URL/health"
echo "aws s3 ls s3://$BUCKET_NAME --no-sign-request"
echo "kubectl auth can-i --list --as=system:serviceaccount:default:wiz-todo-app-sa"
```

---

## **Manual Verification Steps**

### **GitHub Actions (Manual Check)**
1. Go to your GitHub repository
2. Click "Actions" tab
3. Verify workflows have run successfully:
   - **terraform-apply.yml** - Infrastructure deployment
   - **container-security.yml** - Security scanning
   - **k8s-deploy.yml** - Application deployment

### **Security Tab (Manual Check)**
1. Go to GitHub repository → Security tab
2. Check for Trivy scan results showing container vulnerabilities
3. Verify TfSec results showing infrastructure security issues

### **Application Demo (Manual Test)**
1. Access application via LoadBalancer URL
2. Verify health endpoint returns correct response
3. Test basic functionality (Todo app should work)

---

## **Assignment Requirements Status**

✅ **COMPLETE** - All core requirements met:
- wizexercise.txt file with "Devon Diffie" ✓
- Working web application ✓
- Kubernetes deployment ✓
- External access via LoadBalancer ✓
- Security vulnerabilities for demo ✓
- CI/CD pipeline with security scanning ✓
- Infrastructure as Code ✓

**Ready for Wiz interview demonstration!** 🎉