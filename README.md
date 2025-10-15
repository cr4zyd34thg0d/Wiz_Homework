# Wiz Technical Exercise - Cloud Security Demonstration

A comprehensive cloud security demonstration built in my personal AWS account, showcasing common misconfigurations that security tools like Wiz can detect. This project demonstrates my transition from security professional to DevSecOps practitioner.

## 🎯 What This Demonstrates

**Real-world security vulnerabilities in cloud infrastructure:**
- **Public S3 Bucket**: Database backups exposed to the internet (data breach risk)
- **Outdated Infrastructure**: Ubuntu 20.04 + MongoDB 4.4 (4+ years old, known CVEs)
- **Network Exposure**: SSH accessible from anywhere (0.0.0.0/0)
- **Privilege Escalation**: VM can create EC2 instances (excessive IAM permissions)
- **Container Vulnerabilities**: Node.js 16.14.0 + Alpine 3.15 (known security issues)
- **Kubernetes Misconfig**: Service account with cluster-admin privileges
- **Cost-Conscious**: Designed for under $4/day in personal AWS account

### 🏗️ Architecture with CI/CD & Security Scanning

```
┌─────────────────────────────────────────────────────────────────┐
│                        GitHub Repository                         │
│  ┌─────────────────┐    ┌─────────────────────────────────────┐ │
│  │   Source Code   │    │      GitHub Actions CI/CD          │ │
│  │                 │    │                                     │ │
│  │ • Terraform     │───▶│  ┌─────────────────────────────────┐ │ │
│  │ • Kubernetes    │    │  │  1. TfSec Security Scan         │ │ │
│  │ • Application   │    │  │  2. Trivy Container Scan        │ │ │
│  │ • Dockerfile    │    │  │  3. Terraform Apply             │ │ │
│  └─────────────────┘    │  │  4. Container Build & Push      │ │ │
│                         │  │  5. Kubernetes Deploy          │ │ │
│                         │  └─────────────┬───────────────────┘ │ │
│                         └────────────────┼─────────────────────┘ │
└──────────────────────────────────────────┼───────────────────────┘
                                           │ Deploy to AWS
                                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                           AWS Account                            │
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────────────────────────┐ │
│  │   Public Subnet │    │         Private Subnet              │ │
│  │                 │    │                                     │ │
│  │  ┌───────────┐  │    │  ┌─────────────────────────────────┐ │ │
│  │  │    ALB    │  │    │  │        EKS Cluster              │ │ │
│  │  │(Internet  │  │    │  │                                 │ │ │
│  │  │ Facing)   │  │    │  │  ┌─────────────────────────────┐ │ │ │
│  │  └─────┬─────┘  │    │  │  │     Web App Pods            │ │ │ │
│  │        │        │    │  │  │   (with wizexercise.txt)    │ │ │ │
│  │  ┌─────▼─────┐  │    │  │  │   (cluster-admin role)      │ │ │ │
│  │  │MongoDB VM │  │    │  │  └─────────────┬───────────────┘ │ │ │
│  │  │(Outdated) │  │    │  └────────────────┼─────────────────┘ │ │
│  │  │SSH Public │  │    │                   │                   │ │
│  │  │Overly     │  │    │                   │ MongoDB           │ │
│  │  │Permissive │  │    │                   │ Connection        │ │
│  │  └─────┬─────┘  │    │                   │                   │ │
│  └────────┼────────┘    └───────────────────┼───────────────────┘ │
│           │                                 │                     │
│           │ Daily Backup                    │                     │
│           ▼                                 │                     │
│  ┌─────────────────┐                       │                     │
│  │   S3 Bucket     │◄──────────────────────┘                     │
│  │ (Public Read)   │                                             │
│  │ (Public List)   │                                             │
│  └─────────────────┘                                             │
│                                                                 │
│  Security Controls:                                             │
│  ├── CloudTrail (Audit Logging)                                │
│  ├── TfSec (IaC Security Scanning)                             │
│  ├── IAM Deny Policy (Prevent VPC Deletion)                    │
│  └── GitHub OIDC (Secure CI/CD Authentication)                 │
└─────────────────────────────────────────────────────────────────┘
```

## Deployment Options

### Option 1: GitHub Actions CI/CD (Recommended)

**Prerequisites for Personal AWS Account:**
1. **Fork this repository** to your GitHub account
2. **Set up AWS OIDC Provider** in your AWS account for secure GitHub Actions access
3. **Configure GitHub repository secrets:**
   - `AWS_REGION`: us-east-1 (or your preferred region)
   - `AWS_ROLE_TO_ASSUME`: Your AWS IAM role ARN for OIDC authentication
4. **✅ SSH key pair**: Automatically generated by Terraform (no manual setup needed)
5. **Cost Awareness**: This will create real AWS resources (~$4/day)

**Deploy:**
1. Go to Actions tab in your GitHub repository
2. Run "Terraform Apply" workflow manually
3. Wait ~15 minutes for infrastructure deployment
4. Connect to cluster: `aws eks update-kubeconfig --region us-east-1 --name wiz-exercise-dev`
5. Deploy app: `kubectl apply -f k8s/app/`

### Option 2: Manual Local Deployment

**Prerequisites:**
```bash
# Install AWS CLI and configure
aws configure
# Install Terraform (if deploying locally)
# ✅ SSH key pair is automatically generated by Terraform
```

**Deploy:**
```bash
# 1. Deploy infrastructure (~15 minutes)
cd terraform
terraform init
terraform apply
# Type 'yes' when prompted

# 2. Connect to Kubernetes (~5 minutes for EKS to be ready)
aws eks update-kubeconfig --region us-east-1 --name wiz-exercise-dev

# 3. Deploy application
cd ../k8s
kubectl apply -f app/

# 4. Test deployment
../scripts/test-deployment.sh
```

## Security Issues (Intentional)

As a security professional, I've implemented these common misconfigurations:

### Vulnerabilities (Intentional)
- **Public S3 Bucket**: Database backups publicly readable
- **Outdated VM**: Ubuntu 20.04 (4+ years old) with MongoDB 4.4
- **Public SSH**: VM accessible from 0.0.0.0/0
- **Excessive IAM**: VM has ec2:*, s3:*, iam:PassRole permissions
- **Vulnerable Container**: Node.js 16.14.0 with known CVEs
- **Kubernetes Over-Privileges**: Service account has cluster-admin rights

### 🛡️ Security Controls Implemented

**Detective Controls (What Wiz Would Detect):**
- **AWS Config Rule**: `S3_BUCKET_PUBLIC_READ_PROHIBITED` - automatically flags public S3 buckets
- **CloudTrail Logging**: Captures all API calls for audit trail and forensic analysis
- **Compliance Monitoring**: Continuous assessment of security posture

**Preventative Controls (Defense in Depth):**
- **IAM Deny Policy**: Prevents VPC deletion even with broad EC2 permissions
- **Network Segmentation**: EKS cluster isolated in private subnets
- **TfSec Scanning**: Infrastructure-as-Code security analysis in CI/CD pipeline

**DevSecOps Integration:**
- **GitHub OIDC**: Secure authentication without long-term AWS access keys
- **Automated Scanning**: Security checks integrated into deployment pipeline
- **Infrastructure as Code**: All security controls defined and versioned in code

## 🚀 Complete Deployment Guide

### **Prerequisites:**
1. **AWS CLI configured** with appropriate permissions
2. **kubectl installed** and configured
3. **Terraform installed** (v1.12+ recommended)
4. **Helm installed** (for Kubernetes package management)

### **Step-by-Step Deployment:**

#### **1. Deploy Infrastructure (Terraform)**
```bash
cd terraform
terraform init
terraform apply -var="aws_region=us-east-1"
```

#### **2. Configure Kubernetes Access**
```bash
aws eks update-kubeconfig --region us-east-1 --name wiz-exercise-dev
```

#### **3. Deploy Application**
```bash
# Apply Kubernetes manifests
kubectl apply -f k8s/app/

# Create LoadBalancer service for external access
kubectl create service loadbalancer wiz-todo-app --tcp=80:3000
```

#### **4. Configure LoadBalancer Networking**
```bash
# Get ELB name
ELB_NAME=$(kubectl get service wiz-todo-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' | cut -d'-' -f1-4)

# Configure health check
aws elb configure-health-check \
  --load-balancer-name $ELB_NAME \
  --health-check Target=HTTP:$(kubectl get service wiz-todo-app -o jsonpath='{.spec.ports[0].nodePort}')/health,Interval=10,Timeout=5,UnhealthyThreshold=3,HealthyThreshold=2

# Ensure ELB covers both AZs (add us-east-1b subnet if needed)
SUBNET_1B=$(aws ec2 describe-subnets --filters "Name=availability-zone,Values=us-east-1b" "Name=vpc-id,Values=$(aws eks describe-cluster --name wiz-exercise-dev --query 'cluster.resourcesVpcConfig.vpcId' --output text)" "Name=map-public-ip-on-launch,Values=true" --query 'Subnets[0].SubnetId' --output text)
aws elb attach-load-balancer-to-subnets --load-balancer-name $ELB_NAME --subnets $SUBNET_1B
```

#### **5. Verify Deployment**
```bash
# Run comprehensive test
./scripts/test-deployment.sh

# Test application endpoints
ELB_DNS=$(kubectl get service wiz-todo-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl "http://$ELB_DNS/health"
curl "http://$ELB_DNS/api/info"
```

## 🔧 Manual MongoDB VM Creation (If Needed)

If Terraform fails to create the MongoDB VM, you can create it manually:

```bash
# Linux/macOS/WSL
chmod +x scripts/create-mongodb-vm.sh
./scripts/create-mongodb-vm.sh

# Windows PowerShell
.\scripts\create-mongodb-vm.ps1
```

## 🔍 Container Security Scanning

The project includes automated container vulnerability scanning with Trivy:

### Automated Scanning (GitHub Actions):
- **Triggered on**: Push to main/develop, PR to main, or manual dispatch
- **Scans**: Docker images and filesystem for vulnerabilities
- **Reports**: Results uploaded to GitHub Security tab
- **Severity Levels**: CRITICAL, HIGH, MEDIUM vulnerabilities detected

### Manual Scanning:
```bash
# Install Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Scan the application container
cd app
docker build -t wiz-todo-app:scan .
trivy image --severity HIGH,CRITICAL wiz-todo-app:scan

# Scan filesystem for vulnerabilities
trivy fs --severity HIGH,CRITICAL .
```

**How to Demonstrate These Controls:**
```bash
# Show AWS Config detecting public S3 bucket
aws configservice get-compliance-details-by-config-rule \
    --config-rule-name wiz-exercise-dev-s3-public-read-prohibited

# Show CloudTrail audit logging
aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=CreateBucket

# Show IAM deny policy preventing VPC deletion
aws iam get-role-policy --role-name wiz-exercise-dev-mongodb-vm-role \
    --policy-name wiz-exercise-dev-mongodb-vm-policy | grep -A5 "Deny"
```

### DevSecOps Features
- **Infrastructure as Code**: Terraform with security scanning
- **CI/CD Pipeline**: GitHub Actions with automated deployment
- **Version Control**: All code and configurations in Git
- **Automated Testing**: Deployment validation scripts

## Project Structure (Minimal)

```
├── README.md                 # This file
├── terraform/                # Infrastructure as Code
│   ├── main.tf              # All infrastructure (150 lines)
│   └── variables.tf         # Basic variables
├── app/                     # Web application
│   ├── server.js            # Node.js Todo app
│   ├── Dockerfile           # Vulnerable container
│   └── wizexercise.txt      # Required file: "Devon Diffie"
└── k8s/app/                 # Kubernetes manifests
    ├── deployment.yaml      # Pod configuration
    ├── rbac.yaml           # Overprivileged service account
    ├── service.yaml         # Internal networking
    └── ingress.yaml         # Load balancer
```

## 🎯 Demo Scripts for Interview

### Comprehensive Testing and Demonstration
```bash
# 1. Run infrastructure validation tests
./scripts/test-infrastructure.sh

# 2. Demonstrate kubectl capabilities  
./scripts/kubectl-demo.sh

# 3. Show security controls and vulnerabilities
./scripts/demo-security-controls.sh

# 4. Deploy application (if needed)
./scripts/deploy-app.sh
```

### Show Application Working
```bash
# Get application URL
ALB_DNS=$(kubectl get ingress wiz-todo-app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Application: http://$ALB_DNS"

# Verify wizexercise.txt file (requirement)
POD_NAME=$(kubectl get pods -l app=wiz-todo-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD_NAME -- cat /app/wizexercise.txt
# Should show: "Devon Diffie"
```

### Verify Security Issues
The deployment includes several intentional vulnerabilities:
- Kubernetes service account with cluster-admin privileges
- Public S3 bucket with database backups
- Outdated software versions (Ubuntu 20.04, MongoDB 4.4, Node.js 16.14.0)
- VM accessible via SSH from internet
- Excessive IAM permissions allowing resource creation

### 📦 Container Security Demonstration

**How the wizexercise.txt file gets into the container:**
1. **Source File**: Located at `app/wizexercise.txt` containing "Devon Diffie"
2. **Dockerfile Process**: 
   ```dockerfile
   # Copy the required file into container
   COPY . .
   
   # Verify file exists and has correct content (build-time validation)
   RUN echo "Validating wizexercise.txt file..." && \
       test -f wizexercise.txt && \
       cat wizexercise.txt && \
       test "$(cat wizexercise.txt)" = "Devon Diffie"
   ```
3. **Runtime Verification**: File accessible at `/app/wizexercise.txt` in running container
4. **Demo Command**: `kubectl exec $POD_NAME -- cat /app/wizexercise.txt`

**Container Vulnerabilities Explained:**
- **Base Image**: `node:16.14.0-alpine3.15` (intentionally outdated)
- **Known CVEs**: CVE-2022-0778 (OpenSSL), CVE-2022-21824 (Node.js)
- **Security Impact**: Vulnerable to remote code execution and denial of service
- **Detection**: Security scanners like Wiz would flag these immediately

### 🔑 Access MongoDB VM (For Demo)
```bash
# Get the SSH private key (auto-generated by Terraform)
terraform output -raw ssh_private_key > wiz-exercise-keypair.pem
chmod 400 wiz-exercise-keypair.pem

# Get MongoDB VM IP
MONGO_IP=$(aws ec2 describe-instances --filters "Name=tag:Project,Values=wiz-exercise-v4" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

# SSH to MongoDB VM (demonstrates public SSH vulnerability)
ssh -i wiz-exercise-keypair.pem ubuntu@$MONGO_IP

# Once connected, show outdated versions:
lsb_release -a        # Shows Ubuntu 20.04 (4+ years old)
mongod --version      # Shows MongoDB 4.4.18 (outdated)
```

## Cleanup

### Clean Up (Important!)
```bash
# Destroy everything to avoid charges
cd terraform
terraform destroy
# Type 'yes' when prompted

# Verify cleanup
aws ec2 describe-instances --filters "Name=tag:Project,Values=wiz-exercise-v4"
```

## 📋 Available Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `scripts/deploy-app.sh` | Deploy application to EKS | `./scripts/deploy-app.sh` |
| `scripts/test-infrastructure.sh` | Validate all infrastructure | `./scripts/test-infrastructure.sh` |
| `scripts/kubectl-demo.sh` | Demonstrate kubectl commands | `./scripts/kubectl-demo.sh` |
| `scripts/demo-security-controls.sh` | Show security controls | `./scripts/demo-security-controls.sh` |

## Troubleshooting
```bash
# Check if everything is working
./scripts/test-infrastructure.sh

# Common fixes
kubectl get pods -n wiz             # Check pod status
kubectl logs -n wiz -l app=wiz-todo-app   # Check application logs
aws sts get-caller-identity        # Verify AWS credentials
```

## Interview Notes

This demonstrates:
- **Security Issues**: 5 common cloud misconfigurations
- **Security Controls**: 4 detection/prevention mechanisms  
- **Modern Practices**: Infrastructure as Code, containerization, CI/CD
- **Cost Awareness**: Optimized for minimal AWS spend
- **Practical Skills**: Real working environment, not just theory

Perfect for showing security expertise while demonstrating DevOps learning.