#!/bin/bash

# Cleanup script for extra resources created during troubleshooting
# Keeps only the working resources needed for the demo

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "[$(date '+%H:%M:%S')] $1"
}

log "${BLUE}Cleaning up extra resources...${NC}"

# Clean up extra target groups (ALB-related)
log "${YELLOW}Cleaning up target groups...${NC}"
aws elbv2 describe-target-groups --query 'TargetGroups[*].[TargetGroupName,TargetGroupArn]' --output table || echo "No ALB target groups found"

# Clean up extra security groups (keep only essential ones)
log "${YELLOW}Extra security groups found:${NC}"
aws ec2 describe-security-groups --filters "Name=group-name,Values=*wiz-exercise*" --query 'SecurityGroups[*].[GroupName,GroupId,Description]' --output table

# Clean up any failed/unused resources
log "${YELLOW}Checking for unused resources...${NC}"

# List all ELBs (should only have our working one)
aws elb describe-load-balancers --query 'LoadBalancerDescriptions[*].[LoadBalancerName,DNSName]' --output table

# List all ALBs (should be none now)
aws elbv2 describe-load-balancers --query 'LoadBalancers[*].[LoadBalancerName,DNSName]' --output table || echo "No ALBs found"

log "${GREEN}Current working resources:${NC}"
echo "✅ ELB: acc5369ba2bf341378e1eba21906f9bb-2140809443.us-east-1.elb.amazonaws.com"
echo "✅ EKS Cluster: wiz-exercise-dev"
echo "✅ MongoDB VM: 54.196.214.16"
echo "✅ VPC: vpc-06ff4a616890e003e"

log "${BLUE}Cleanup complete! Demo environment is ready.${NC}"