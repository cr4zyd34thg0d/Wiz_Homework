# Wiz Technical Exercise - Minimal Configuration
# Creates intentional vulnerabilities for security demonstration

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  name_prefix = "wiz-exercise-${var.environment}"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "${local.name_prefix}-vpc" }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "${local.name_prefix}-igw" }
}

# Public subnets for ALB (need 2 AZs)
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = { Name = "${local.name_prefix}-public-${count.index + 1}" }
}

# Private subnets for EKS (REQUIRED)
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = { Name = "${local.name_prefix}-private-${count.index + 1}" }
}

# NAT Gateway for private subnets
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = { Name = "${local.name_prefix}-nat-eip" }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags = { Name = "${local.name_prefix}-nat" }
  depends_on = [aws_internet_gateway.main]
}

# Route table for public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "${local.name_prefix}-public-rt" }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  tags = { Name = "${local.name_prefix}-private-rt" }
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Security group for MongoDB VM (VULNERABLE)
resource "aws_security_group" "mongodb_vm" {
  name        = "${local.name_prefix}-mongodb-vm"
  description = "MongoDB VM - INTENTIONALLY VULNERABLE"
  vpc_id      = aws_vpc.main.id

  # SSH from anywhere (VULNERABILITY)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # MongoDB port
  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Public S3 bucket (VULNERABLE)
resource "aws_s3_bucket" "backup" {
  bucket = "${local.name_prefix}-backup-${random_string.bucket_suffix.result}"
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_public_access_block" "backup" {
  bucket = aws_s3_bucket.backup.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "backup_public" {
  bucket = aws_s3_bucket.backup.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.backup.arn}/*"
      },
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:ListBucket"
        Resource  = aws_s3_bucket.backup.arn
      }
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.backup]
}

# Ubuntu 20.04 AMI (1+ year outdated)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# Overly permissive IAM role (VULNERABLE)
resource "aws_iam_role" "mongodb_vm" {
  name = "${local.name_prefix}-mongodb-vm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "mongodb_vm_policy" {
  name = "${local.name_prefix}-mongodb-vm-policy"
  role = aws_iam_role.mongodb_vm.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["ec2:*", "s3:*", "iam:PassRole"]
        Resource = "*"
      },
      {
        Effect = "Deny"
        Action = ["ec2:DeleteVpc"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "mongodb_vm" {
  name = "${local.name_prefix}-mongodb-vm-profile"
  role = aws_iam_role.mongodb_vm.name
}

# MongoDB VM (VULNERABLE)
resource "aws_instance" "mongodb" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.mongodb_vm.id]
  subnet_id              = aws_subnet.public[0].id
  iam_instance_profile   = aws_iam_instance_profile.mongodb_vm.name

  user_data = base64encode(<<-EOF
#!/bin/bash
apt-get update
# Install MongoDB 4.4 (outdated)
wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list
apt-get update
apt-get install -y mongodb-org=4.4.18

# Configure MongoDB with authentication
cat > /etc/mongod.conf << 'MONGOCONF'
storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true

systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

net:
  port: 27017
  bindIp: 0.0.0.0

processManagement:
  fork: true
  pidFilePath: /var/run/mongodb/mongod.pid

security:
  authorization: enabled
MONGOCONF

systemctl start mongod
systemctl enable mongod

# Wait for MongoDB to start
sleep 10

# Create admin user and todoapp database
mongo << 'MONGOJS'
use admin
db.createUser({
  user: "admin",
  pwd: "password123",
  roles: [ { role: "userAdminAnyDatabase", db: "admin" }, "readWriteAnyDatabase" ]
})

use todoapp
db.createUser({
  user: "todoapp",
  pwd: "todopass",
  roles: [ { role: "readWrite", db: "todoapp" } ]
})

db.todos.insertMany([
  {"task": "Review security policies", "completed": false, "user": "admin"},
  {"task": "Update database passwords", "completed": false, "user": "admin"},
  {"task": "Complete Wiz demo", "completed": true, "user": "devon"}
])

db.users.insertMany([
  {"username": "admin", "email": "admin@company.com", "role": "admin"},
  {"username": "devon", "email": "devon@company.com", "role": "user"}
])
MONGOJS

# Install AWS CLI
apt-get install -y awscli

# Daily backup script with authentication
cat > /opt/mongodb-backup.sh << 'SCRIPT'
#!/bin/bash
DATE=$(date +%Y-%m-%d)
mongodump --host localhost --port 27017 --username admin --password password123 --authenticationDatabase admin --db todoapp --out /tmp/backup-$DATE
tar -czf /tmp/backup-$DATE.tar.gz -C /tmp backup-$DATE
aws s3 cp /tmp/backup-$DATE.tar.gz s3://${aws_s3_bucket.backup.bucket}/mongodb-backups/
rm -rf /tmp/backup-$DATE*
SCRIPT
chmod +x /opt/mongodb-backup.sh

# Run initial backup
/opt/mongodb-backup.sh

# Schedule daily backups
echo "0 2 * * * root /opt/mongodb-backup.sh" >> /etc/crontab
EOF
  )

  tags = { Name = "${local.name_prefix}-mongodb" }
}

# EKS Cluster (REQUIRED)
resource "aws_security_group" "eks_cluster" {
  name        = "${local.name_prefix}-eks-cluster"
  description = "EKS cluster security group"
  vpc_id      = aws_vpc.main.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "eks_cluster" {
  name = "${local.name_prefix}-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_eks_cluster" "main" {
  name     = local.name_prefix
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.28"

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.eks_cluster.id]
  }

  # Enable cluster access for root user
  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

# Add root user access to EKS cluster
resource "aws_eks_access_entry" "root_user" {
  cluster_name      = aws_eks_cluster.main.name
  principal_arn     = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  kubernetes_groups = ["cluster-admin"]
  type             = "STANDARD"
}

# ECR Repository for container images
resource "aws_ecr_repository" "app" {
  name                 = "${local.name_prefix}-app"
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# EKS Node Group
resource "aws_iam_role" "eks_nodes" {
  name = "${local.name_prefix}-eks-nodes-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${local.name_prefix}-nodes"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = aws_subnet.private[*].id
  instance_types  = ["t3.small"]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
  ]
}



# CloudTrail (REQUIRED - Control plane audit logging)
resource "aws_s3_bucket" "cloudtrail" {
  bucket = "${local.name_prefix}-cloudtrail-${random_string.bucket_suffix.result}"
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail.arn}/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "main" {
  name           = "${local.name_prefix}-cloudtrail"
  s3_bucket_name = aws_s3_bucket.cloudtrail.bucket
  depends_on = [aws_s3_bucket_policy.cloudtrail]
}

# AWS Config (DETECTIVE CONTROL - detects public S3 buckets)
resource "aws_s3_bucket" "config" {
  bucket = "${local.name_prefix}-config-${random_string.bucket_suffix.result}"
}

resource "aws_iam_role" "config" {
  name = "${local.name_prefix}-config-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "config.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_iam_role_policy" "config_s3" {
  name = "${local.name_prefix}-config-s3-policy"
  role = aws_iam_role.config.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetBucketAcl",
        "s3:PutObject", 
        "s3:GetObject",
        "s3:ListBucket"
      ]
      Resource = [
        aws_s3_bucket.config.arn,
        "${aws_s3_bucket.config.arn}/*"
      ]
    }]
  })
}

# AWS Config is already configured in CloudLabs environment
# Using existing Config service for compliance monitoring

# Config rule to detect public S3 buckets (DETECTIVE CONTROL)
# Note: Uses existing AWS Config service in CloudLabs
resource "aws_config_config_rule" "s3_bucket_public_read_prohibited" {
  name = "${local.name_prefix}-s3-public-read-prohibited"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }
}

# Additional Config rules for compliance monitoring
# Note: Uses existing AWS Config service in CloudLabs
resource "aws_config_config_rule" "s3_bucket_ssl_requests_only" {
  name = "${local.name_prefix}-s3-ssl-requests-only"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SSL_REQUESTS_ONLY"
  }
}

resource "aws_config_config_rule" "cloudtrail_enabled" {
  name = "${local.name_prefix}-cloudtrail-enabled"
  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENABLED"
  }
}

# Load balancing will be handled by Kubernetes LoadBalancer service
# This creates a Classic ELB automatically when you run:
# kubectl create service loadbalancer wiz-todo-app --tcp=80:3000

# Create SSH key pair for MongoDB VM (Demo purposes)
resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "main" {
  key_name   = var.key_pair_name
  public_key = tls_private_key.main.public_key_openssh
}

# Get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Outputs
output "mongodb_public_ip" {
  value = aws_instance.mongodb.public_ip
}

output "backup_bucket_name" {
  value = aws_s3_bucket.backup.bucket
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "eks_cluster_name" {
  value = aws_eks_cluster.main.name
}

output "ssh_private_key" {
  description = "Private key for SSH access to MongoDB VM"
  value       = tls_private_key.main.private_key_pem
  sensitive   = true
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.app.dns_name
}

output "alb_target_group_arn" {
  description = "ARN of the ALB target group for pod registration"
  value       = aws_lb_target_group.app.arn
}