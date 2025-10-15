# Architecture

Built a vulnerable cloud setup to show security issues that Wiz would catch. Costs about $4/day in my AWS account.

## What's Built

```
GitHub Actions → AWS
     ↓
┌─────────────────────────────────┐
│ VPC with public/private subnets │
│                                 │
│ Public:                         │
│ • MongoDB VM (old Ubuntu)       │
│ • SSH open to world             │
│ • Load balancer                 │
│                                 │
│ Private:                        │
│ • EKS cluster                   │
│ • App pods with admin rights    │
│                                 │
│ Storage:                        │
│ • Public S3 bucket              │
│ • ECR for containers            │
└─────────────────────────────────┘
```
## Security Issues (on purpose)

- Public S3 bucket with database backups
- SSH open to the world on MongoDB VM
- Old Ubuntu and MongoDB versions
- Kubernetes service account with admin rights
- Way too many IAM permissions

## What Works

- GitHub Actions deploys everything automatically
- Security scanning built into the pipeline
- App runs in Kubernetes and connects to MongoDB
- wizexercise.txt file is in the container

## For Demo

```bash
# Check the required file
kubectl exec pod-name -- cat /app/wizexercise.txt

# Show security issues
./scripts/demo-security-controls.sh
```

Shows I can build real infrastructure with actual security problems that Wiz would catch.