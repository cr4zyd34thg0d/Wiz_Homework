# Variables for Wiz Exercise with Remote State Management

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project name for resource naming"
  type        = string
  default     = "wiz-exercise"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "key_pair_name" {
  description = "EC2 Key Pair for SSH access"
  type        = string
  default     = "wiz-exercise-keypair"
}

variable "mongo_ami" {
  description = "AMI ID for MongoDB VM (Ubuntu 18.04)"
  type        = string
  default     = ""
}

variable "mongo_instance_type" {
  description = "Instance type for MongoDB VM"
  type        = string
  default     = "t3.small"
}

# State management variables (used by CI/CD)
variable "tf_state_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
  default     = ""
}

variable "tf_lock_table" {
  description = "DynamoDB table for Terraform state locking"
  type        = string
  default     = ""
}