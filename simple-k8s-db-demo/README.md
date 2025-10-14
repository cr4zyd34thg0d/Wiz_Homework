# 🎯 Simple K8s + Vulnerable DB Demo

A straightforward demonstration of Kubernetes cluster with vulnerable database connectivity.

## 📋 What This Covers

**Core Requirements (Based on Your Info):**
- ✅ K8s cluster in the cloud
- ✅ VM with vulnerable database
- ✅ Connectivity between K8s and DB
- ✅ Infrastructure as Code (Terraform)
- ✅ GitHub repository
- ✅ CI/CD pipeline (bonus)

## 🏗️ Simple Architecture

```
┌─────────────────┐    ┌─────────────────┐
│   EKS Cluster   │    │   EC2 Instance  │
│                 │    │                 │
│  ┌───────────┐  │    │  ┌───────────┐  │
│  │    App    │  │◄───┼──┤   MySQL   │  │
│  │   Pod     │  │    │  │   DVWA    │  │
│  └───────────┘  │    │  └───────────┘  │
└─────────────────┘    └─────────────────┘
```

## 📁 Project Structure (Simplified)

```
simple-k8s-db-demo/
├── terraform/
│   ├── main.tf           # EKS + EC2 setup
│   ├── variables.tf      # Configuration
│   └── outputs.tf        # Important values
├── k8s/
│   ├── app.yaml          # Simple app deployment
│   └── service.yaml      # Service to expose app
├── scripts/
│   ├── setup-db.sh       # Install DVWA on EC2
│   └── test-connection.sh # Test K8s to DB
├── .github/workflows/
│   └── deploy.yml        # Simple CI/CD
├── .env.example          # Configuration template
├── Makefile              # Easy commands
└── README.md             # This file
```

## 🚀 Quick Demo Flow (5-10 minutes)

1. **Show GitHub repo** (30 seconds)
2. **Explain Terraform files** (2 minutes)
3. **Deploy with one command** (2 minutes)
4. **Show K8s cluster** (2 minutes)
5. **Test DB connectivity** (2 minutes)
6. **Show CI/CD pipeline** (1 minute)

## 💡 Key Talking Points

- **Infrastructure as Code**: "Everything is defined in Terraform"
- **Cloud Native**: "Using AWS EKS for managed Kubernetes"
- **Security**: "Vulnerable DB is isolated but accessible"
- **Automation**: "One command deploys everything"
- **Monitoring**: "Can see connectivity and health"

## 🎤 Simple Presentation Script

**"I've created a cloud infrastructure that demonstrates Kubernetes connectivity to a vulnerable database. Let me walk you through it..."**

1. **"Here's my GitHub repository with all the code"**
2. **"The Terraform files define our AWS infrastructure"**
3. **"I can deploy everything with 'make deploy'"**
4. **"Here's the live Kubernetes cluster with our application"**
5. **"And here's the vulnerable database running on EC2"**
6. **"The app successfully connects to the database"**
7. **"The CI/CD pipeline automates the entire process"**

## 🔧 Easy Commands

```bash
# Deploy everything
make deploy

# Test connectivity
make test

# Show status
make status

# Clean up
make cleanup
```

## 📊 What You'll Demonstrate

- ✅ **Working K8s cluster** in AWS
- ✅ **Vulnerable database** (DVWA) on EC2
- ✅ **Successful connectivity** between them
- ✅ **Infrastructure as Code** with Terraform
- ✅ **CI/CD pipeline** with GitHub Actions
- ✅ **Professional documentation** and organization

---

**This version is much simpler but still shows all the key skills they're looking for!**

Wait for the actual requirements, then we can adjust this template to match exactly what they want. This gives you a solid foundation that's easy to explain and expand upon.

Would you like me to create this simplified version, or should we wait for the specific requirements first?