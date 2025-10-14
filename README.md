# Wiz Technical Exercise

A cloud security demonstration showing common misconfigurations that security tools like Wiz can detect. Built by a security professional learning DevOps practices.

## What This Demonstrates

Minimal security demonstration with intentional vulnerabilities:
- **Public S3 Bucket**: Database backups publicly accessible
- **Outdated VM**: Ubuntu 20.04 with MongoDB 4.4 (1+ year old)
- **Public SSH**: VM accessible from internet
- **Excessive IAM**: VM can create other AWS resources
- **Vulnerable Container**: Outdated Node.js with known CVEs
- **Cost-Optimized**: Under $2/day using t3.micro instances

### 🏗️ Architecture with CI/CD

```
┌─────────────────────────────────────────────────────────────────┐
│                        GitHub Repository                         │
│  ┌─────────────────┐    ┌─────────────────────────────────────┐ │
│  │   Source Code   │    │      GitHub Actions CI/CD          │ │
│  │                 │    │                                     │ │
│  │ • Terraform     │───▶│  ┌─────────────────────────────────┐ │ │
│  │ • Kubernetes    │    │  │  1. TfSec Security Scan         │ │ │
│  │ • Application   │    │  │  2. Terraform Apply             │ │ │
│  │ • Dockerfile    │    │  │  3. Container Build & Push      │ │ │
│  └─────────────────┘    │  │  4. Kubernetes Deploy          │ │ │
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

**Prerequisites:**
1. Fork this repository to your GitHub account
2. Set up GitHub repository secrets:
   - `AWS_REGION`: us-east-1
   - `AWS_ROLE_TO_ASSUME`: Your AWS IAM role ARN for OIDC
3. Create SSH key: `aws ec2 create-key-pair --key-name wiz-exercise-keypair`

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
# Create SSH key for MongoDB access
aws ec2 create-key-pair --key-name wiz-exercise-keypair --query 'KeyMaterial' --output text > wiz-exercise-keypair.pem
chmod 400 wiz-exercise-keypair.pem
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

### Security Controls Implemented
- **Detective Control**: AWS Config rule detects public S3 buckets
- **Preventative Control**: IAM deny policy prevents VPC deletion
- **Infrastructure Scanning**: TfSec scans Terraform for security issues
- **Secure CI/CD**: GitHub OIDC authentication (no long-term AWS keys)

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

## Demo Commands for Interview

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

## Troubleshooting
```bash
# Check if everything is working
./scripts/test-deployment.sh

# Common fixes
kubectl get pods                    # Check pod status
kubectl logs -l app=wiz-todo-app   # Check application logs
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