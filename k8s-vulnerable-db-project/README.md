# 🚀 Kubernetes Vulnerable Database Project

A comprehensive cloud infrastructure project demonstrating K8s cluster deployment, vulnerable database setup, and DevOps best practices with CI/CD pipeline.

## 📋 Project Overview

This project implements:
- **Kubernetes cluster** in the cloud (AWS EKS)
- **Vulnerable database** (DVWA + MySQL) running in VM
- **Infrastructure as Code** (Terraform)
- **CI/CD Pipeline** (GitHub Actions)
- **Security monitoring** and connectivity testing
- **Comprehensive documentation** and presentation materials

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS Cloud                            │
│  ┌─────────────────┐    ┌─────────────────────────────────┐ │
│  │   EKS Cluster   │    │        EC2 Instance             │ │
│  │                 │    │  ┌─────────────────────────────┐ │ │
│  │  ┌───────────┐  │    │  │     Vulnerable DB           │ │ │
│  │  │   App     │  │◄───┼──┤  - DVWA (PHP/Apache)        │ │ │
│  │  │   Pods    │  │    │  │  - MySQL Database           │ │ │
│  │  └───────────┘  │    │  │  - Intentional Vulns        │ │ │
│  │                 │    │  └─────────────────────────────┘ │ │
│  └─────────────────┘    └─────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
k8s-vulnerable-db-project/
├── terraform/                  # Infrastructure as Code
│   ├── main.tf                # Main Terraform configuration
│   ├── variables.tf           # Variable definitions
│   ├── outputs.tf             # Output values
│   ├── eks.tf                 # EKS cluster configuration
│   ├── ec2.tf                 # EC2 instance for vulnerable DB
│   ├── networking.tf          # VPC, subnets, security groups
│   └── versions.tf            # Provider versions
├── k8s/                       # Kubernetes manifests
│   ├── namespace.yaml         # Application namespace
│   ├── deployment.yaml        # Application deployment
│   ├── service.yaml           # Service definitions
│   ├── configmap.yaml         # Configuration data
│   └── ingress.yaml           # Ingress controller
├── scripts/                   # Automation scripts
│   ├── setup-vulnerable-db.sh # DB setup script
│   ├── test-connectivity.sh   # Connection testing
│   ├── deploy.sh              # Deployment automation
│   └── cleanup.sh             # Resource cleanup
├── .github/workflows/         # CI/CD Pipeline
│   ├── terraform.yml          # Infrastructure pipeline
│   ├── k8s-deploy.yml         # K8s deployment pipeline
│   └── security-scan.yml      # Security scanning
├── config/                    # Configuration files
│   ├── app-config.yaml        # Application configuration
│   ├── db-config.yaml         # Database configuration
│   └── security-config.yaml   # Security settings
├── docs/                      # Documentation
│   ├── ARCHITECTURE.md        # Architecture overview
│   ├── DEPLOYMENT.md          # Deployment guide
│   ├── SECURITY.md            # Security considerations
│   └── PRESENTATION.md        # Presentation notes
├── presentation/              # Presentation materials
│   ├── slides.md              # Presentation slides
│   ├── demo-script.md         # Demo walkthrough
│   └── images/                # Architecture diagrams
├── tests/                     # Testing scripts
│   ├── connectivity-tests.py  # Connection tests
│   ├── security-tests.py      # Security validation
│   └── integration-tests.py   # End-to-end tests
├── docker/                    # Container definitions
│   ├── app/                   # Application container
│   └── monitoring/            # Monitoring tools
├── monitoring/                # Observability
│   ├── prometheus.yaml        # Metrics collection
│   ├── grafana.yaml           # Dashboards
│   └── alerts.yaml            # Alert rules
├── .gitignore                 # Git ignore rules
├── .env.example               # Environment variables template
├── Makefile                   # Automation commands
└── README.md                  # This file
```

## 🎯 Key Features

### **Infrastructure as Code (Terraform)**
- AWS EKS cluster with managed node groups
- EC2 instance for vulnerable database
- VPC with proper networking and security groups
- IAM roles and policies with least privilege
- State management with S3 backend

### **Kubernetes Deployment**
- Containerized application connecting to vulnerable DB
- Proper resource limits and requests
- ConfigMaps and Secrets management
- Ingress controller for external access
- Namespace isolation

### **Vulnerable Database Setup**
- DVWA (Damn Vulnerable Web Application)
- MySQL database with intentional misconfigurations
- Multiple vulnerability types (SQL injection, XSS, etc.)
- Monitoring and logging capabilities

### **CI/CD Pipeline (GitHub Actions)**
- Infrastructure provisioning automation
- Kubernetes deployment pipeline
- Security scanning (Trivy, Checkov)
- Automated testing and validation
- Multi-environment support (dev/staging/prod)

### **Security & Monitoring**
- Network security groups and NACLs
- Container security scanning
- Database connection encryption
- Prometheus metrics collection
- Grafana dashboards for visualization

## 🚀 Quick Start

### Prerequisites
- AWS CLI configured
- kubectl installed
- Terraform >= 1.0
- Docker installed
- GitHub account

### 1. Clone and Setup
```bash
git clone <your-repo>
cd k8s-vulnerable-db-project
cp .env.example .env
# Edit .env with your AWS credentials and preferences
```

### 2. Deploy Infrastructure
```bash
make terraform-init
make terraform-plan
make terraform-apply
```

### 3. Setup Kubernetes
```bash
make k8s-setup
make k8s-deploy
```

### 4. Configure Vulnerable Database
```bash
make setup-vulnerable-db
make test-connectivity
```

### 5. Access Applications
```bash
make get-endpoints
```

## 🔧 Configuration

All configuration is managed through:
- **Environment variables** (`.env` file)
- **Terraform variables** (`terraform/variables.tf`)
- **Kubernetes ConfigMaps** (`config/`)
- **Application config files** (`config/`)

## 🧪 Testing

```bash
# Run all tests
make test

# Individual test suites
make test-connectivity
make test-security
make test-integration
```

## 📊 Monitoring

Access monitoring dashboards:
- **Grafana**: `http://<grafana-endpoint>`
- **Prometheus**: `http://<prometheus-endpoint>`
- **Application**: `http://<app-endpoint>`

## 🔒 Security Considerations

- Network segmentation with security groups
- Encrypted data in transit and at rest
- IAM roles with minimal permissions
- Container image scanning
- Vulnerability assessment reports

## 📈 Presentation Points

1. **Architecture Overview** - Cloud-native design
2. **Infrastructure as Code** - Terraform automation
3. **Kubernetes Best Practices** - Resource management, security
4. **CI/CD Pipeline** - Automated deployment and testing
5. **Security Implementation** - Defense in depth
6. **Monitoring & Observability** - Comprehensive visibility
7. **Scalability & Reliability** - Production-ready design

## 🎤 Demo Script

1. Show GitHub repository structure
2. Walk through Terraform infrastructure code
3. Demonstrate CI/CD pipeline execution
4. Show live K8s cluster and pods
5. Connect to vulnerable database
6. Display monitoring dashboards
7. Run security scans and tests

## 🧹 Cleanup

```bash
make cleanup-all
```

## 📚 Additional Resources

- [Architecture Documentation](docs/ARCHITECTURE.md)
- [Deployment Guide](docs/DEPLOYMENT.md)
- [Security Analysis](docs/SECURITY.md)
- [Presentation Materials](presentation/)

---

**Built with ❤️ for cloud security and DevOps excellence**