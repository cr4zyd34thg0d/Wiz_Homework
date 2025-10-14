# Wiz Technical Exercise - Interview Explanation Guide

## 🎯 Project Overview for Interview

**"I built a comprehensive cloud security demonstration in my personal AWS account to showcase real-world vulnerabilities that security tools like Wiz would detect. This project demonstrates my transition from security professional to DevSecOps practitioner."**

## 🏗️ Architecture Explanation

### **Infrastructure Components:**
- **AWS VPC**: Isolated network with public/private subnets
- **MongoDB VM**: Ubuntu 20.04 in public subnet (intentionally vulnerable)
- **EKS Cluster**: Kubernetes in private subnets with vulnerable application
- **S3 Buckets**: Public backup bucket + secure Config bucket
- **Security Controls**: AWS Config, CloudTrail, IAM policies

### **CI/CD Pipeline:**
- **GitHub Repository**: Infrastructure as Code + application code
- **GitHub Actions**: Automated deployment with security scanning
- **TfSec Integration**: Infrastructure security analysis
- **OIDC Authentication**: Secure AWS access without long-term keys

## 🚨 Security Vulnerabilities Demonstrated

### **1. Public S3 Bucket (HIGH RISK)**
**What**: Database backup bucket publicly readable
**Why Dangerous**: Exposes sensitive data to internet
**Business Impact**: Data breach, compliance violations, reputation damage
**Wiz Detection**: Immediate alert on public bucket policy
**Demo Command**: `aws s3 ls s3://[bucket-name] --recursive`

### **2. Outdated Infrastructure (MEDIUM-HIGH RISK)**
**What**: Ubuntu 20.04 (4+ years old) + MongoDB 4.4.18
**Why Dangerous**: Known CVEs, unpatched vulnerabilities
**Business Impact**: Remote code execution, data compromise
**Wiz Detection**: Vulnerability scanning, patch management alerts
**Demo Command**: `ssh ubuntu@[vm-ip] "lsb_release -a && mongod --version"`

### **3. Network Exposure (MEDIUM RISK)**
**What**: SSH accessible from 0.0.0.0/0
**Why Dangerous**: Brute force attacks, unauthorized access
**Business Impact**: System compromise, lateral movement
**Wiz Detection**: Network exposure analysis
**Demo Command**: Show security group rules in AWS console

### **4. Container Vulnerabilities (MEDIUM-HIGH RISK)**
**What**: Node.js 16.14.0 + Alpine 3.15 (outdated)
**Why Dangerous**: CVE-2022-0778, CVE-2022-21824
**Business Impact**: Container escape, application compromise
**Wiz Detection**: Container image scanning
**Demo Command**: `kubectl exec [pod] -- node --version`

### **5. Kubernetes Over-Privileges (CRITICAL RISK)**
**What**: Service account has cluster-admin privileges
**Why Dangerous**: Can delete entire cluster, access all secrets
**Business Impact**: Complete infrastructure compromise
**Wiz Detection**: RBAC analysis, privilege escalation paths
**Demo Command**: `kubectl auth can-i create nodes --as=system:serviceaccount:default:wiz-todo-app-sa`

### **6. Excessive IAM Permissions (MEDIUM RISK)**
**What**: VM can create EC2 instances (ec2:*)
**Why Dangerous**: Privilege escalation, resource creation
**Business Impact**: Unauthorized costs, security bypass
**Wiz Detection**: IAM analysis, permission boundaries
**Demo Command**: Show IAM policy with ec2:* permissions

## 🛡️ Security Controls Implemented

### **Detective Controls:**
- **AWS Config**: Detects public S3 buckets automatically
- **CloudTrail**: Audit logging for forensic analysis
- **Compliance Monitoring**: Continuous security posture assessment

### **Preventative Controls:**
- **IAM Deny Policy**: Prevents VPC deletion despite broad permissions
- **Network Segmentation**: EKS in private subnets
- **TfSec Scanning**: Infrastructure security in CI/CD

## 📦 Container File Demonstration

### **wizexercise.txt File Process:**
1. **Source**: File exists at `app/wizexercise.txt` with content "Devon Diffie"
2. **Build Time**: Dockerfile validates file exists and has correct content
3. **Runtime**: File accessible at `/app/wizexercise.txt` in container
4. **Verification**: `kubectl exec [pod] -- cat /app/wizexercise.txt`

### **Why This Matters:**
- **Requirement Compliance**: Meets Wiz exercise specifications
- **Build Validation**: Ensures file is present before deployment
- **Runtime Verification**: Proves container contains required file
- **Security Context**: Shows how files get into containers

## 💰 Cost Management

### **Personal AWS Account Considerations:**
- **Daily Cost**: ~$4/day during demo period
- **Resource Optimization**: t3.micro/small instances, single EKS node
- **Cleanup Process**: Terraform destroy removes all resources
- **Cost Monitoring**: CloudWatch billing alerts configured

### **Production vs Demo:**
- **Demo**: Minimal viable infrastructure for security demonstration
- **Production**: Would include HA, auto-scaling, monitoring, backup strategies

## 🎤 Interview Talking Points

### **Technical Expertise:**
- "I understand both the security risks and the infrastructure patterns"
- "This demonstrates real vulnerabilities I've seen in enterprise environments"
- "The security controls show defense-in-depth thinking"

### **DevOps Learning:**
- "I'm transitioning from pure security to DevSecOps practices"
- "This project taught me Infrastructure as Code and container orchestration"
- "I see how security integrates into the development lifecycle"

### **Business Value:**
- "These vulnerabilities have real business impact - data breaches, compliance failures"
- "Wiz provides the unified visibility that security teams need"
- "Early detection prevents incidents that could cost millions"

## 🔧 Demo Flow for Interview

### **1. Architecture Overview (5 minutes)**
- Show diagram, explain components
- Highlight intentional vulnerabilities
- Discuss security controls

### **2. Live Demonstration (15 minutes)**
- Show working application
- Demonstrate each vulnerability
- Show security controls in action

### **3. Business Impact Discussion (10 minutes)**
- Explain real-world implications
- Discuss how Wiz would detect issues
- Connect to business value

### **4. Technical Deep Dive (10 minutes)**
- Answer technical questions
- Discuss implementation choices
- Show code and configurations

### **5. Wrap-up (5 minutes)**
- Summarize learning experience
- Discuss next steps in DevSecOps journey
- Ask questions about Wiz platform

## 🚀 Key Success Metrics

### **Technical Demonstration:**
- ✅ All vulnerabilities working and demonstrable
- ✅ Security controls functioning properly
- ✅ Application accessible and functional
- ✅ Infrastructure deployed via automation

### **Interview Performance:**
- ✅ Clear explanation of security risks
- ✅ Understanding of business impact
- ✅ Demonstration of learning mindset
- ✅ Connection to Wiz value proposition