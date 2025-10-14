# Deployed Infrastructure

Quick reference for what actually gets created when you run `terraform apply`:

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                AWS Account (us-east-1)                          │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                            VPC (10.0.0.0/16)                               │ │
│  │                                                                             │ │
│  │  ┌─────────────────────────┐    ┌─────────────────────────────────────────┐ │ │
│  │  │     Public Subnets      │    │           Private Subnets               │ │ │
│  │  │                         │    │                                         │ │ │
│  │  │  ┌─────────────────────┐ │    │  ┌─────────────────────────────────────┐ │ │ │
│  │  │  │   us-east-1a        │ │    │  │           us-east-1a                │ │ │ │
│  │  │  │   10.0.1.0/24       │ │    │  │         10.0.10.0/24                │ │ │ │
│  │  │  │                     │ │    │  │                                     │ │ │ │
│  │  │  │  ┌───────────────┐  │ │    │  │  ┌─────────────────────────────────┐ │ │ │ │
│  │  │  │  │ MongoDB VM    │  │ │    │  │  │        EKS Cluster              │ │ │ │ │
│  │  │  │  │ (Ubuntu 20.04)│  │ │    │  │  │                                 │ │ │ │ │
│  │  │  │  │ SSH: 0.0.0.0/0│  │ │    │  │  │  ┌─────────────────────────────┐ │ │ │ │ │
│  │  │  │  │ MongoDB 4.4   │  │ │    │  │  │  │      Worker Nodes           │ │ │ │ │ │
│  │  │  │  │ IAM: ec2:*    │  │ │    │  │  │  │                             │ │ │ │ │ │
│  │  │  │  └───────────────┘  │ │    │  │  │  │  ┌─────────────────────────┐ │ │ │ │ │ │
│  │  │  │                     │ │    │  │  │  │  │    Todo App Pods        │ │ │ │ │ │ │
│  │  │  │  ┌───────────────┐  │ │    │  │  │  │  │  Node.js 16.14.0        │ │ │ │ │ │ │
│  │  │  │  │ Application   │  │ │    │  │  │  │  │  Alpine 3.15            │ │ │ │ │ │ │
│  │  │  │  │ Load Balancer │  │ │    │  │  │  │  │  cluster-admin SA       │ │ │ │ │ │ │
│  │  │  │  │ (ALB)         │  │ │    │  │  │  │  │  wizexercise.txt        │ │ │ │ │ │ │
│  │  │  │  └───────────────┘  │ │    │  │  │  │  └─────────────────────────┘ │ │ │ │ │ │
│  │  │  └─────────────────────┘ │    │  │  │  └─────────────────────────────┐ │ │ │ │ │
│  │  │                          │    │  │  └─────────────────────────────────┘ │ │ │ │
│  │  │  ┌─────────────────────┐ │    │  │                                     │ │ │ │
│  │  │  │   us-east-1b        │ │    │  │  ┌─────────────────────────────────┐ │ │ │ │
│  │  │  │   10.0.2.0/24       │ │    │  │  │           us-east-1b            │ │ │ │ │
│  │  │  │                     │ │    │  │  │         10.0.11.0/24            │ │ │ │ │
│  │  │  │  ┌───────────────┐  │ │    │  │  │                                 │ │ │ │ │
│  │  │  │  │   NAT Gateway │  │ │    │  │  │  ┌─────────────────────────────┐ │ │ │ │ │
│  │  │  │  │               │  │ │    │  │  │  │      Worker Nodes           │ │ │ │ │ │
│  │  │  │  └───────────────┘  │ │    │  │  │  └─────────────────────────────┘ │ │ │ │ │
│  │  │  └─────────────────────┘ │    │  │  └─────────────────────────────────┘ │ │ │ │
│  │  └─────────────────────────┘    │  └─────────────────────────────────────┘ │ │ │
│  │                                 │                                          │ │ │
│  └─────────────────────────────────┴──────────────────────────────────────────┘ │ │
│                                                                                 │ │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │ │
│  │                              S3 Storage                                    │ │ │
│  │                                                                             │ │ │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐ │ │ │
│  │  │ 🔓 Backup Bucket│  │ 🔒 Config Bucket│  │ 🔒 CloudTrail Bucket       │ │ │ │
│  │  │ (PUBLIC READ)   │  │ (Private)       │  │ (Private)                   │ │ │ │
│  │  │ - DB Backups    │  │ - Config Logs   │  │ - API Audit Logs            │ │ │ │
│  │  │ - VULNERABILITY │  │ - Compliance    │  │ - Security Monitoring       │ │ │ │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘ │ │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │ │
│                                                                                 │ │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │ │
│  │                          Security & Monitoring                             │ │ │
│  │                                                                             │ │ │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐ │ │ │
│  │  │   CloudTrail    │  │   AWS Config    │  │      IAM Roles & Policies   │ │ │ │
│  │  │                 │  │                 │  │                             │ │ │ │
│  │  │ - API Logging   │  │ - S3 Public     │  │ - EKS Service Role          │ │ │ │
│  │  │ - Audit Trail   │  │   Detection     │  │ - MongoDB VM Role (ec2:*)   │ │ │ │
│  │  │ - Compliance    │  │ - SSL Enforce   │  │ - Config Service Role       │ │ │ │
│  │  │                 │  │ - CloudTrail    │  │ - CloudTrail Service Role   │ │ │ │
│  │  │                 │  │   Monitoring    │  │                             │ │ │ │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘ │ │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │ │
└─────────────────────────────────────────────────────────────────────────────────┘ │
                                                                                   │
┌─────────────────────────────────────────────────────────────────────────────────┘
│                              GitHub Actions CI/CD                              
│                                                                                 
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────────┐ 
│  │  Terraform      │  │  Container      │  │      Kubernetes                 │ 
│  │  Pipeline       │  │  Security       │  │      Deployment                 │ 
│  │                 │  │                 │  │                                 │ 
│  │ - TfSec Scan    │  │ - Trivy Scan    │  │ - Apply Manifests               │ 
│  │ - Plan & Apply  │  │ - Vulnerability │  │ - Create LoadBalancer           │ 
│  │ - OIDC Auth     │  │   Detection     │  │ - Health Checks                 │ 
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────────┘ 
└─────────────────────────────────────────────────────────────────────────────────┘
```

## What Gets Created

**Networking:**
- VPC with public/private subnets in 2 AZs
- Internet Gateway and NAT Gateway
- Route tables for proper traffic flow

**Compute:**
- EKS cluster with worker nodes in private subnets
- MongoDB VM (t3.micro) in public subnet
- Application Load Balancer for external access

**Storage:**
- Backup S3 bucket (intentionally public)
- Config and CloudTrail buckets (private)

**Security:**
- CloudTrail for API logging
- AWS Config with 3 compliance rules
- IAM roles for all services

**Application:**
- Node.js Todo app running in Kubernetes
- Service account with cluster-admin (over-privileged)
- LoadBalancer service for external access

## Security Issues (For Demo)

**Critical:**
- Public S3 bucket with database backups
- SSH access from anywhere (0.0.0.0/0)
- Over-privileged IAM role (ec2:*, s3:*)

**High:**
- Outdated software stack (Ubuntu 20.04, MongoDB 4.4, Node.js 16.14.0)
- Kubernetes service account with cluster-admin
- Container vulnerabilities in base images

## CI/CD Pipelines (GitHub Actions)

**Terraform Pipeline (.github/workflows/terraform-apply.yml):**
- Triggered on push to main or manual dispatch
- TfSec security scanning of infrastructure code
- OIDC authentication to AWS (no stored credentials)
- Terraform plan and apply

**Container Security (.github/workflows/container-security.yml):**
- Trivy vulnerability scanning of Docker images
- Scans for CVEs in Node.js 16.14.0 and Alpine 3.15
- Results uploaded to GitHub Security tab
- Runs on push and PR events

**Kubernetes Deployment (.github/workflows/k8s-deploy.yml):**
- Deploys application to EKS cluster
- Creates LoadBalancer service
- Runs health checks and validation

## Security Controls

**Detection:**
- AWS Config rules for compliance monitoring
- CloudTrail for audit logging
- Container vulnerability scanning in CI/CD (Trivy)
- Infrastructure security scanning (TfSec)

**Prevention:**
- Network segmentation (EKS in private subnets)
- IAM deny policies
- Infrastructure as code for consistency
- OIDC authentication (no long-term AWS keys)

This setup demonstrates real security issues that Wiz would catch and help fix, while also showing modern DevSecOps practices with security integrated into the CI/CD pipeline.