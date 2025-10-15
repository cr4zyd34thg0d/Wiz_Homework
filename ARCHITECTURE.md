# Architecture Overview

## What I Built

This is a vulnerable cloud environment I created to demonstrate security issues that Wiz would detect. Coming from a security background, I wanted to build something that shows real problems I've encountered, while also learning modern DevOps practices.

The setup costs me about $3-4/day to run in my personal AWS account.

## Complete Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  GitHub Repository                          │
│                                                             │
│  Source Code:           CI/CD Pipelines:                   │
│  ┌─────────────────┐    ┌─────────────────────────────────┐ │
│  │ • Terraform     │───▶│  1. TfSec Security Scan         │ │
│  │ • Kubernetes    │    │  2. Terraform Apply             │ │
│  │ • Node.js App   │    │  3. Trivy Container Scan        │ │
│  │ • Dockerfile    │    │  4. Build & Push Image          │ │
│  └─────────────────┘    │  5. Deploy to EKS               │ │
│                         └─────────────┬───────────────────┘ │
└─────────────────────────────────────────┼───────────────────┘
                                          │ Deploy to AWS
                                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    AWS (us-east-1)                          │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                VPC (10.0.0.0/16)                       │ │
│  │                                                         │ │
│  │  Public Subnets          Private Subnets               │ │
│  │  ┌─────────────────┐    ┌─────────────────────────────┐ │ │
│  │  │                 │    │                             │ │ │
│  │  │  Load Balancer  │    │      EKS Cluster            │ │ │
│  │  │  (ALB)          │    │                             │ │ │
│  │  │                 │    │  ┌─────────────────────────┐ │ │ │
│  │  │  MongoDB VM     │    │  │    Todo App Pods        │ │ │ │
│  │  │  - Ubuntu 20.04 │    │  │    - Node.js 18         │ │ │ │
│  │  │  - SSH: 0.0.0.0/0│   │  │    - cluster-admin SA   │ │ │ │
│  │  │  - IAM: ec2:*   │    │  │    - wizexercise.txt    │ │ │ │
│  │  │                 │    │  │    - Images from ECR    │ │ │ │
│  │  │                 │    │  └─────────────────────────┘ │ │ │
│  │  └─────────────────┘    └─────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  Container Registry:        S3 Storage:                     │
│  ┌─────────────────┐        ┌─────────────────────────────┐ │
│  │ ECR Repository  │        │ Backup Bucket (PUBLIC!)    │ │
│  │ - Todo App      │        │ CloudTrail (Private)       │ │
│  │   Images        │        │ Config (Private)           │ │
│  │ - Vulnerability │        └─────────────────────────────┘ │
│  │   Scanning      │                                        │
│  └─────────────────┘        Security Monitoring:           │
│                             ┌─────────────────────────────┐ │
│                             │ • CloudTrail (API logs)     │ │
│                             │ • AWS Config (compliance)   │ │
│                             │ • Container scanning (ECR)  │ │
│                             │ • Infrastructure scanning   │ │
│                             └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## The Problems (Intentional)

Based on my security experience, these are the most common issues I see:

**Critical Issues:**
- **Public S3 bucket** - Database backups anyone can download
- **SSH from anywhere** - MongoDB server accessible from internet
- **Over-privileged IAM** - VM can create/delete EC2 instances

**High Risk:**
- **Outdated software** - Ubuntu 20.04 (4+ years old), MongoDB 4.4 (EOL Feb 2024)
- **Kubernetes over-privileges** - Service account has cluster-admin
- **Database credentials exposed** - MongoDB credentials in Kubernetes ConfigMap

## Security Controls I Added

**Detection:**
- AWS Config rules to catch public S3 buckets
- CloudTrail for audit logging
- Container scanning in CI/CD pipeline

**Prevention:**
- EKS cluster in private subnets
- IAM deny policy to prevent VPC deletion
- Infrastructure as code for consistency

## CI/CD Pipeline & Security Scanning

The whole thing is automated through GitHub Actions - this was a big learning curve for me coming from security:

**Terraform Pipeline:**
- TfSec scans infrastructure code for security issues
- Terraform plan/apply with OIDC authentication (no long-term keys)
- Deploys VPC, EKS, MongoDB VM, S3 buckets, monitoring

**Container Security Pipeline:**
- Docker images built and pushed to ECR
- Trivy scans container images for vulnerabilities
- ECR vulnerability scanning enabled
- Container security scanning integrated into CI/CD
- Results uploaded to GitHub Security tab

**Kubernetes Deployment:**
- Applies manifests to EKS cluster
- Creates LoadBalancer service
- Runs health checks

This DevSecOps approach means security is baked into the deployment process, not bolted on afterward.

## Tech Stack

- **Infrastructure:** Terraform
- **Containers:** Docker + Kubernetes (EKS) + ECR
- **Application:** Node.js Todo app
- **Database:** MongoDB on EC2
- **CI/CD:** GitHub Actions with security scanning
- **Container Registry:** AWS ECR with vulnerability scanning
- **Monitoring:** CloudTrail, AWS Config

## Demo Points

1. **Show the public S3 bucket** - `aws s3 ls s3://bucket-name --no-sign-request`
2. **Check Kubernetes permissions** - `kubectl auth can-i --list --as=system:serviceaccount:wiz:wiz-todo-app-sa`
3. **Verify wizexercise.txt** - `kubectl exec pod-name -- cat /app/wizexercise.txt`
4. **SSH to MongoDB VM** - Show it's accessible from anywhere

This demonstrates both security knowledge and modern DevOps practices - exactly what I'm bringing to the DevSecOps role.