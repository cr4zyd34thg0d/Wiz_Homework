# Manual Deployment Guide for Wiz Interview

## 🎯 **Recommended Approach for Interview**

For maximum control during the interview, use **manual workflow triggers** instead of automatic deployment.

## 📋 **Step-by-Step Manual Deployment**

### **1. Infrastructure Deployment**
```bash
# Go to GitHub Actions → Infrastructure Deployment (IaC) → Run workflow
# This will:
# - Create EKS cluster, MongoDB VM, S3 buckets
# - Set up security controls (Config rules, CloudTrail)
# - Take ~15 minutes
```

### **2. Container & Kubernetes Deployment** 
```bash
# After infrastructure completes:
# Go to GitHub Actions → Container Build & Kubernetes Deploy → Run workflow
# Leave inputs as "auto-detect" - it will find the MongoDB IP automatically
# This will:
# - Build and push container image
# - Deploy to Kubernetes with LoadBalancer
# - Take ~5 minutes
```

### **3. Verification**
```bash
# Run validation scripts locally:
./scripts/test-infrastructure.sh
./scripts/kubectl-demo.sh
./scripts/demo-security-controls.sh
```

## 🚨 **If Something Goes Wrong**

### **Cleanup (Destroy Everything)**
```bash
# Go to GitHub Actions → Terraform Destroy (Cleanup) → Run workflow
# Type "DESTROY" in the confirmation field
# This will remove all AWS resources
```

### **Local Terraform (Backup Method)**
```bash
cd terraform
terraform init -backend-config=backend.conf
terraform destroy -auto-approve
```

## 🎯 **Interview Demo Flow**

1. **Show GitHub Actions** - Demonstrate CI/CD pipeline
2. **Run Infrastructure Workflow** - Show Terraform deployment
3. **Run Container Workflow** - Show container build and K8s deploy
4. **Run Demo Scripts** - Show security vulnerabilities
5. **Show Cleanup** - Demonstrate responsible resource management

## 🔧 **Troubleshooting**

### **Credentials Error**
- Ensure GitHub repository secrets are configured:
  - `AWS_ROLE_TO_ASSUME` (OIDC role ARN)
  - `AWS_REGION` (us-east-1)

### **Workflow Dependencies**
- Always run Infrastructure first
- Wait for Infrastructure to complete before running Container workflow
- Use "auto-detect" for MongoDB IP and cluster name

### **Resource Conflicts**
- If deployment fails, run Terraform Destroy first
- Then retry the Infrastructure workflow

## 💡 **Pro Tips for Interview**

- **Manual control** prevents unexpected deployments during demo
- **Workflows show DevOps skills** while maintaining control
- **Scripts demonstrate** comprehensive testing and validation
- **Cleanup shows** responsible cloud resource management

This approach gives you full control while showcasing professional CI/CD practices!