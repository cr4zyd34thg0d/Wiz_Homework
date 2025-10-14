# Architecture Documentation

## High-Level Architecture

This demonstrates a typical cloud application with intentional security misconfigurations for security tool evaluation.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              AWS Account (us-east-1)                        │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                            VPC (10.0.0.0/16)                           │ │
│  │                                                                         │ │
│  │  ┌─────────────────────┐         ┌─────────────────────────────────────┐ │ │
│  │  │   Public Subnets    │         │         Private Subnets             │ │ │
│  │  │   (10.0.1.0/24)     │         │        (10.0.10.0/24)              │ │ │
│  │  │   (10.0.2.0/24)     │         │        (10.0.20.0/24)              │ │ │
│  │  │                     │         │                                     │ │ │
│  │  │  ┌───────────────┐  │         │  ┌─────────────────────────────────┐ │ │ │
│  │  │  │      ALB      │  │         │  │         EKS Cluster             │ │ │ │
│  │  │  │  (Internet    │  │         │  │        (1 t3.small node)        │ │ │ │
│  │  │  │   Facing)     │  │         │  │                                 │ │ │ │
│  │  │  └───────┬───────┘  │         │  │  ┌─────────────────────────────┐ │ │ │ │
│  │  │          │          │         │  │  │      Todo App Pods          │ │ │ │ │
│  │  │  ┌───────▼───────┐  │         │  │  │   - wizexercise.txt         │ │ │ │ │
│  │  │  │  MongoDB VM   │  │         │  │  │   - cluster-admin RBAC      │ │ │ │ │
│  │  │  │  (t3.micro)   │  │         │  │  │   - Node.js application     │ │ │ │ │
│  │  │  │               │  │         │  │  └─────────────┬───────────────┘ │ │ │ │
│  │  │  │ VULNERABILITIES│  │         │  └────────────────┼─────────────────┘ │ │ │
│  │  │  │ - Ubuntu 20.04│  │         │                   │                   │ │ │
│  │  │  │ - MongoDB 4.4 │  │         │                   │ MongoDB           │ │ │
│  │  │  │ - SSH Public  │  │         │                   │ Connection        │ │ │
│  │  │  │ - IAM Excess  │  │         │                   │                   │ │ │
│  │  │  └───────┬───────┘  │         │                   │                   │ │ │
│  │  └──────────┼──────────┘         └───────────────────┼───────────────────┘ │ │
│  └─────────────┼────────────────────────────────────────┼─────────────────────┘ │
│                │                                        │                       │
│                │ Daily Backup                           │                       │
│                ▼                                        │                       │
│  ┌─────────────────────────────────────────────────────┼─────────────────────┐ │
│  │                    S3 Buckets                       │                     │ │
│  │                                                     │                     │ │
│  │  ┌─────────────────────┐         ┌─────────────────▼───────────────────┐ │ │
│  │  │   Backup Bucket     │         │      CloudTrail Bucket             │ │ │
│  │  │   (PUBLIC READ!)    │         │      (Audit Logs)                  │ │ │
│  │  │                     │         │                                     │ │ │
│  │  │ VULNERABILITY:      │         │ - API Activity Logs                │ │ │
│  │  │ - Public Access     │         │ - Multi-Region                     │ │ │
│  │  │ - Anyone can read   │         │ - Encrypted                        │ │ │
│  │  │ - Database backups  │         │                                     │ │ │
│  │  └─────────────────────┘         └─────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                        Security Controls                                │ │
│  │                                                                         │ │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────┐ │ │
│  │  │   CloudTrail    │  │   AWS Config    │  │    Service Control      │ │ │
│  │  │                 │  │                 │  │    Policy (SCP)         │ │ │
│  │  │ - API Logging   │  │ - S3 Public     │  │                         │ │ │
│  │  │ - Multi-Region  │  │   Detection     │  │ - Prevents VPC          │ │ │
│  │  │ - Encryption    │  │ - Compliance    │  │   Deletion              │ │ │
│  │  │ - Data Events   │  │   Monitoring    │  │ - Organizational        │ │ │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Network Architecture

### VPC Design
- **CIDR**: 10.0.0.0/16 (65,536 IP addresses)
- **Public Subnets**: 10.0.1.0/24, 10.0.2.0/24 (ALB, MongoDB VM)
- **Private Subnets**: 10.0.10.0/24, 10.0.20.0/24 (EKS cluster)
- **Multi-AZ**: Deployed across 2 availability zones for ALB requirements

### Security Groups
```
MongoDB VM Security Group:
├── Inbound Rules:
│   ├── SSH (22) from 0.0.0.0/0 ← VULNERABILITY
│   └── MongoDB (27017) from Private Subnets only
└── Outbound Rules:
    └── All traffic to 0.0.0.0/0

EKS Cluster Security Group:
├── Inbound Rules:
│   └── Managed by AWS EKS
└── Outbound Rules:
    └── All traffic to 0.0.0.0/0

EKS Nodes Security Group:
├── Inbound Rules:
│   ├── Node-to-node communication
│   └── Cluster-to-node communication
└── Outbound Rules:
    └── All traffic to 0.0.0.0/0
```

## Application Architecture

### Container Application
- **Base**: Node.js 18 on Alpine Linux
- **Application**: Simple Todo list with MongoDB backend
- **Required File**: `/app/wizexercise.txt` containing "Devon Diffie"
- **Health Endpoints**: `/health`, `/ready`, `/live`
- **API Endpoints**: CRUD operations for todos, file validation

### Kubernetes Deployment
```yaml
# RBAC Vulnerability (intentional)
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: wiz-todo-app-cluster-admin
subjects:
- kind: ServiceAccount
  name: wiz-todo-app-sa
  namespace: default
roleRef:
  kind: ClusterRole
  name: cluster-admin  # ← VULNERABILITY: Too much access
  apiGroup: rbac.authorization.k8s.io
```

## Security Vulnerabilities (Intentional)

### 1. Public S3 Bucket
- **Location**: MongoDB backup storage
- **Issue**: Publicly readable and listable
- **Impact**: Database backups exposed to internet
- **Business Risk**: Data breach, compliance violations

### 2. Kubernetes RBAC Over-Privileges
- **Location**: Application service account
- **Issue**: cluster-admin role assigned
- **Impact**: Application can do anything in cluster
- **Business Risk**: Complete cluster compromise

### 3. Outdated Software
- **Location**: MongoDB VM
- **Issue**: Ubuntu 20.04 and MongoDB 4.4 (1+ years old)
- **Impact**: Known CVEs and security patches missing
- **Business Risk**: Automated exploitation, data theft

### 4. Public SSH Access
- **Location**: MongoDB VM security group
- **Issue**: SSH port 22 open to 0.0.0.0/0
- **Impact**: Brute force attacks, unauthorized access
- **Business Risk**: Server compromise, lateral movement

### 5. Excessive IAM Permissions
- **Location**: MongoDB VM IAM role
- **Issue**: Can create/modify EC2 instances
- **Impact**: Privilege escalation, resource creation
- **Business Risk**: Cost impact, further compromise

## Security Controls (Detection & Prevention)

### 1. AWS CloudTrail
- **Purpose**: Audit logging for all AWS API calls
- **Configuration**: Multi-region, encrypted, data events enabled
- **Detection**: Tracks all resource access and modifications
- **Value**: Complete audit trail for compliance and forensics

### 2. AWS Config
- **Purpose**: Compliance monitoring and configuration drift detection
- **Rules**: S3 bucket public access detection
- **Detection**: Automatically identifies public S3 buckets
- **Value**: Continuous compliance monitoring

### 3. Service Control Policy (SCP)
- **Purpose**: Preventive control at organizational level
- **Policy**: Prevents VPC deletion
- **Prevention**: Blocks destructive actions even by admin users
- **Value**: Infrastructure protection against accidents/malicious actions

### 4. Network Segmentation
- **Purpose**: Limit blast radius of compromises
- **Implementation**: EKS in private subnets, controlled egress
- **Prevention**: Reduces attack surface and lateral movement
- **Value**: Defense in depth architecture

## Cost Optimization

### Daily Cost Breakdown (~$4.35/day)
- **EKS Cluster**: $2.40/day ($0.10/hour)
- **EC2 Instances**: $1.20/day (t3.small + t3.micro)
- **Application Load Balancer**: $0.60/day ($0.025/hour)
- **S3 Storage**: $0.10/day (minimal data)
- **CloudTrail/Config**: $0.05/day (basic logging)

### Cost Optimization Strategies
- Single EKS node (no redundancy for demo)
- Smallest viable instance types
- Minimal data storage
- Basic monitoring and logging

## Deployment Flow

```
Developer → GitHub → GitHub Actions → AWS
    │         │           │            │
    │         │           │            ├── Terraform (Infrastructure)
    │         │           │            ├── ECR (Container Registry)
    │         │           │            └── EKS (Application Deployment)
    │         │           │
    │         │           ├── Security Scanning
    │         │           │   ├── TFSec (Terraform)
    │         │           │   └── Trivy (Container)
    │         │           │
    │         │           └── Automated Deployment
    │         │               ├── terraform apply
    │         │               └── kubectl apply
    │         │
    │         └── Version Control
    │             ├── Branch Protection
    │             ├── Required Reviews
    │             └── Status Checks
    │
    └── Local Development
        ├── terraform init/plan/apply
        ├── kubectl commands
        └── Testing scripts
```

## Monitoring and Observability

### CloudWatch Integration
- **EKS Cluster**: Control plane logs, node metrics
- **Application**: Container logs, health check metrics
- **Infrastructure**: EC2 metrics, ALB metrics
- **Security**: CloudTrail events, Config compliance

### Key Metrics to Monitor
- Pod restart counts (application stability)
- Database connection errors (connectivity issues)
- Failed authentication attempts (security events)
- Resource utilization (cost optimization)

## Disaster Recovery

### Backup Strategy
- **MongoDB**: Daily automated backups to S3
- **Application**: Container images in ECR
- **Infrastructure**: Terraform state and configuration
- **Recovery Time**: ~20 minutes for complete rebuild

### Recovery Procedures
1. **Infrastructure**: `terraform apply` from version control
2. **Application**: `kubectl apply` with latest container images
3. **Database**: Restore from S3 backup to new MongoDB instance
4. **Validation**: Run test scripts to verify functionality

This architecture demonstrates real-world cloud security challenges while maintaining cost efficiency and operational simplicity suitable for a technical interview demonstration.