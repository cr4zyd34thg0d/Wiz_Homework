# Architecture

Built a vulnerable cloud setup to show security issues that Wiz would catch. Costs about $4/day in my AWS account.

## Detailed Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        GitHub Repository                         │
│                                                                 │
│  Source Code:           CI/CD Pipelines:                       │
│  ┌─────────────────┐    ┌─────────────────────────────────────┐ │
│  │ • Terraform     │───▶│  1. TfSec Security Scan             │ │
│  │ • Kubernetes    │    │  2. Infrastructure Deploy           │ │
│  │ • Node.js App   │    │  3. Trivy Container Scan            │ │
│  │ • Dockerfile    │    │  4. Build & Push to ECR             │ │
│  └─────────────────┘    │  5. Deploy to EKS                   │ │
│                         └─────────────┬───────────────────────┘ │
└─────────────────────────────────────────┼───────────────────────┘
                                          │ Deploy to AWS
                                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AWS Account (us-east-1)                      │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                VPC (10.0.0.0/16)                           │ │
│  │                                                             │ │
│  │  Public Subnets (10.0.1.0/24, 10.0.2.0/24)               │ │
│  │  ┌─────────────────────────────────────────────────────────┐ │ │
│  │  │                                                         │ │ │
│  │  │  ┌─────────────────┐    ┌─────────────────────────────┐ │ │ │
│  │  │  │ Classic ELB     │    │ MongoDB VM (t3.micro)       │ │ │ │
│  │  │  │ (Auto-created)  │    │ • Ubuntu 20.04 (outdated)  │ │ │ │
│  │  │  │                 │    │ • MongoDB 4.4 (EOL)        │ │ │ │
│  │  │  │                 │    │ • SSH: 0.0.0.0/0 (vuln)    │ │ │ │
│  │  │  │                 │    │ • IAM: ec2:*, s3:* (vuln)  │ │ │ │
│  │  │  └─────────────────┘    │ • IP: 10.0.1.87             │ │ │ │
│  │  │                         └─────────────────────────────┘ │ │ │
│  │  └─────────────────────────────────────────────────────────┘ │ │
│  │                                                             │ │
│  │  Private Subnets (10.0.10.0/24, 10.0.11.0/24)            │ │
│  │  ┌─────────────────────────────────────────────────────────┐ │ │
│  │  │                                                         │ │ │
│  │  │              EKS Cluster (wiz-exercise-dev)            │ │ │
│  │  │                                                         │ │ │
│  │  │  ┌─────────────────────────────────────────────────────┐ │ │ │
│  │  │  │                Node Group                           │ │ │ │
│  │  │  │                                                     │ │ │ │
│  │  │  │  ┌─────────────────────────────────────────────────┐ │ │ │ │
│  │  │  │  │            Todo App Pods (2 replicas)          │ │ │ │ │
│  │  │  │  │                                                 │ │ │ │ │
│  │  │  │  │ • Node.js 16.14.0 (vulnerable)                 │ │ │ │ │
│  │  │  │  │ • Alpine 3.15 (outdated)                       │ │ │ │ │
│  │  │  │  │ • wizexercise.txt: "Devon Diffie"              │ │ │ │ │
│  │  │  │  │ • Service Account: cluster-admin (vuln)        │ │ │ │ │
│  │  │  │  │ • MongoDB connection: 10.0.1.87:27017          │ │ │ │ │
│  │  │  │  └─────────────────────────────────────────────────┘ │ │ │ │
│  │  │  └─────────────────────────────────────────────────────┘ │ │ │
│  │  └─────────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                 │
│  Container Registry:        S3 Storage:                         │
│  ┌─────────────────┐        ┌─────────────────────────────────┐ │
│  │ ECR Repository  │        │ Backup Bucket (PUBLIC READ!)   │ │
│  │ • wiz-todo-app  │        │ • Database backups exposed     │ │
│  │ • Vuln scanning │        │ • Public list/read policy      │ │
│  └─────────────────┘        │                                 │ │
│                             │ CloudTrail Bucket (Private)     │ │
│                             │ • API audit logs               │ │
│                             │                                 │ │
│                             │ Config Bucket (Private)         │ │
│                             │ • Compliance monitoring         │ │
│                             └─────────────────────────────────┘ │
│                                                                 │
│  Security Monitoring:                                           │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ • CloudTrail (API audit logging)                           │ │
│  │ • AWS Config Rules (compliance monitoring)                 │ │
│  │ • TfSec (Infrastructure security scanning)                 │ │
│  │ • Trivy (Container vulnerability scanning)                 │ │
│  │ • ECR Image Scanning (automated)                           │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Network Flow

```
Internet → Classic ELB → EKS Pods → MongoDB VM
    ↓           ↓           ↓           ↓
  Port 80   Port 32731   Port 3000   Port 27017
                                        ↓
                                   S3 Backup
                                  (Public Read!)
```
## Infrastructure Components

### Networking
- **VPC**: 10.0.0.0/16 with public/private subnets across 2 AZs
- **Public Subnets**: 10.0.1.0/24, 10.0.2.0/24 (MongoDB VM, Load Balancer)
- **Private Subnets**: 10.0.10.0/24, 10.0.11.0/24 (EKS cluster)
- **NAT Gateway**: Allows private subnet internet access
- **Internet Gateway**: Public subnet internet access

### Compute
- **EKS Cluster**: Kubernetes 1.28, managed control plane
- **Node Group**: t3.small instances, 1-2 nodes auto-scaling
- **MongoDB VM**: t3.micro Ubuntu 20.04 with MongoDB 4.4

### Storage
- **ECR**: Container registry with vulnerability scanning
- **S3 Buckets**: 
  - Backup bucket (PUBLIC - vulnerability)
  - CloudTrail logs (private)
  - Config data (private)

### Security & Monitoring
- **CloudTrail**: API call logging and audit trail
- **AWS Config**: Compliance rules and configuration monitoring
- **IAM Roles**: EKS cluster, node group, MongoDB VM permissions
- **Security Groups**: Network access controls

## CI/CD Pipeline Details

### Infrastructure Pipeline
1. **TfSec Scan**: Scans Terraform for security issues
2. **Terraform Plan**: Shows what will be created
3. **Terraform Apply**: Creates AWS infrastructure
4. **Output Collection**: Gets cluster name, MongoDB IP, etc.

### Container Pipeline  
1. **Trivy Filesystem Scan**: Scans source code for vulnerabilities
2. **Docker Build**: Creates container with wizexercise.txt
3. **Trivy Image Scan**: Scans built container for CVEs
4. **ECR Push**: Uploads image to container registry
5. **Kubernetes Deploy**: Applies all manifests to EKS
6. **Health Checks**: Verifies deployment success

## Security Issues (Intentional)

### Critical
- **Public S3 Bucket**: Database backups readable by anyone
- **SSH Open to World**: MongoDB VM accessible from 0.0.0.0/0
- **Excessive IAM**: VM can create/delete EC2 instances, full S3 access

### High Risk
- **Outdated VM Software**: Ubuntu 20.04 (4+ years), MongoDB 4.4 (EOL Feb 2024)
- **Kubernetes Over-Privileges**: Service account has cluster-admin rights
- **Credentials in ConfigMap**: MongoDB connection string in plain text

## Security Controls

### Detective Controls
- **AWS Config Rules**: Detects public S3 buckets, SSH exposure
- **CloudTrail**: Logs all API calls for forensic analysis
- **Container Scanning**: Trivy + ECR scan for vulnerabilities

### Preventative Controls
- **Network Segmentation**: EKS in private subnets
- **IAM Permission Boundary**: Prevents VPC deletion
- **Infrastructure as Code**: Consistent, versioned deployments
## Demo Commands

```bash
# 1. Check deployment status
kubectl get all -n wiz

# 2. Verify wizexercise.txt requirement
POD_NAME=$(kubectl get pods -n wiz -l app=wiz-todo-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n wiz $POD_NAME -- cat /app/wizexercise.txt
# Output: "Devon Diffie"

# 3. Test app connectivity
kubectl exec -n wiz $POD_NAME -- wget -qO- http://localhost:3000/health
kubectl exec -n wiz $POD_NAME -- wget -qO- http://localhost:3000/api/info

# 4. Show public S3 bucket vulnerability
BUCKET_NAME=$(cd terraform && terraform output -raw backup_bucket_name)
aws s3 ls s3://$BUCKET_NAME --no-sign-request

# 5. Check Kubernetes over-privileges
kubectl auth can-i --list --as=system:serviceaccount:wiz:wiz-todo-app-sa | head -10

# 6. Get external application URL
ELB_URL=$(kubectl get service wiz-todo-service -n wiz -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "External URL: http://$ELB_URL"
curl "http://$ELB_URL/health"

# 7. Test MongoDB connection (should show connected: true)
curl "http://$ELB_URL/api/info"
```

This demonstrates real security issues that Wiz would detect in a production environment.