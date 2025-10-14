# Minimal Variables for Wiz Exercise

variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  default     = "dev"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "key_pair_name" {
  description = "EC2 Key Pair for SSH access"
  default     = "wiz-exercise-keypair"
}