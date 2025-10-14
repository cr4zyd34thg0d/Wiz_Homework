# Variables for K8s Vulnerable Database Project

# AWS Configuration
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "aws_profile" {
  description = "AWS profile to use"
  type        = string
  default     = "default"
}

# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "k8s-vulnerable-db"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "interview-candidate"
}

# EKS Cluster Configuration
variable "cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "node_group_instance_types" {
  description = "Instance types for EKS node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_group_min_size" {
  description = "Minimum number of nodes in node group"
  type        = number
  default     = 1
}

variable "node_group_max_size" {
  description = "Maximum number of nodes in node group"
  type        = number
  default     = 3
}

variable "node_group_desired_size" {
  description = "Desired number of nodes in node group"
  type        = number
  default     = 2
}

# EC2 Instance Configuration (Vulnerable Database)
variable "db_instance_type" {
  description = "Instance type for vulnerable database"
  type        = string
  default     = "t3.small"
}

variable "db_ami_id" {
  description = "AMI ID for database instance"
  type        = string
  default     = "ami-0c02fb55956c7d316" # Amazon Linux 2
}

variable "db_key_pair_name" {
  description = "Key pair name for database instance"
  type        = string
  default     = ""
}

# Database Configuration
variable "db_root_password" {
  description = "Root password for MySQL database"
  type        = string
  default     = "VulnerablePassword123!"
  sensitive   = true
}

variable "db_name" {
  description = "Name of the vulnerable database"
  type        = string
  default     = "dvwa"
}

variable "db_user" {
  description = "Database user for application"
  type        = string
  default     = "dvwa_user"
}

variable "db_password" {
  description = "Database password for application"
  type        = string
  default     = "dvwa_password"
  sensitive   = true
}

# Network Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access resources"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Application Configuration
variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "db-connector"
}

variable "app_image" {
  description = "Container image for application"
  type        = string
  default     = "nginx:latest"
}

variable "app_port" {
  description = "Port for application"
  type        = number
  default     = 80
}

variable "app_replicas" {
  description = "Number of application replicas"
  type        = number
  default     = 2
}

# Monitoring Configuration
variable "enable_monitoring" {
  description = "Enable monitoring stack"
  type        = bool
  default     = true
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  default     = "admin123"
  sensitive   = true
}

variable "prometheus_retention" {
  description = "Prometheus data retention period"
  type        = string
  default     = "15d"
}

# Security Configuration
variable "enable_security_scanning" {
  description = "Enable security scanning"
  type        = bool
  default     = true
}

# Terraform Backend Configuration (Optional)
variable "tf_state_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
  default     = ""
}

variable "tf_state_key" {
  description = "S3 key for Terraform state"
  type        = string
  default     = "k8s-vulnerable-db/terraform.tfstate"
}

variable "tf_state_region" {
  description = "AWS region for Terraform state bucket"
  type        = string
  default     = "us-west-2"
}

variable "tf_dynamodb_table" {
  description = "DynamoDB table for Terraform state locking"
  type        = string
  default     = ""
}