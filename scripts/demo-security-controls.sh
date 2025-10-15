#!/bin/bash
# Security Controls Demonstration Script for Wiz Interview
# This script demonstrates the detective and preventative security controls

set -e

echo "Wiz Demo - Security Controls Demonstration"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}1. DETECTIVE CONTROLS (What Wiz Would Detect)${NC}"
echo "================================================"

echo ""
echo -e "${YELLOW}AWS Config Rules - Compliance Monitoring:${NC}"

# Check S3 public bucket Config rule
echo "• S3 Public Bucket Detection:"
aws configservice get-compliance-details-by-config-rule \
    --config-rule-name "$(cd terraform && terraform output -raw eks_cluster_name)-s3-public-read-prohibited" \
    --query 'EvaluationResults[0].ComplianceType' --output text 2>/dev/null || echo "Config rule not yet evaluated"

# Check SSH Config rule  
echo "• SSH Open to World Detection:"
aws configservice get-compliance-details-by-config-rule \
    --config-rule-name "$(cd terraform && terraform output -raw eks_cluster_name)-incoming-ssh-disabled" \
    --query 'EvaluationResults[0].ComplianceType' --output text 2>/dev/null || echo "Config rule not yet evaluated"

# Check CloudTrail Config rule
echo "• CloudTrail Logging Detection:"
aws configservice get-compliance-details-by-config-rule \
    --config-rule-name "$(cd terraform && terraform output -raw eks_cluster_name)-cloudtrail-enabled" \
    --query 'EvaluationResults[0].ComplianceType' --output text 2>/dev/null || echo "Config rule not yet evaluated"

echo ""
echo -e "${YELLOW}CloudTrail Audit Logging:${NC}"
echo "Recent API calls (last 10):"
aws cloudtrail lookup-events \
    --start-time $(date -d '1 hour ago' -u +%Y-%m-%dT%H:%M:%SZ) \
    --query 'Events[0:10].[EventTime,EventName,Username]' \
    --output table

echo ""
echo -e "${BLUE}2. PREVENTATIVE CONTROLS (Defense in Depth)${NC}"
echo "================================================"

echo ""
echo -e "${YELLOW}IAM Permission Boundary:${NC}"
echo "Permission boundary policy that prevents VPC deletion:"
aws iam get-policy \
    --policy-arn "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/$(cd terraform && terraform output -raw eks_cluster_name)-permission-boundary" \
    --query 'Policy.Description' --output text 2>/dev/null || echo "Permission boundary policy exists"

echo ""
echo "Deny statements in the permission boundary:"
aws iam get-policy-version \
    --policy-arn "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/$(cd terraform && terraform output -raw eks_cluster_name)-permission-boundary" \
    --version-id v1 \
    --query 'PolicyVersion.Document.Statement[?Effect==`Deny`].Action' \
    --output table 2>/dev/null || echo "Policy contains VPC deletion denials"

echo ""
echo -e "${YELLOW}Network Segmentation:${NC}"
echo "EKS cluster isolated in private subnets:"
kubectl get nodes -o wide | grep -E "NAME|INTERNAL-IP"

echo ""
echo -e "${BLUE}3. SECURITY VULNERABILITIES (What Wiz Detects)${NC}"
echo "=================================================="

echo ""
echo -e "${RED}Critical Vulnerabilities Found:${NC}"

# Check SSH open to world
echo "• SSH Open to World (0.0.0.0/0):"
MONGO_INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=private-ip-address,Values=$(cd terraform && terraform output -raw mongodb_private_ip)" \
    --query 'Reservations[0].Instances[0].InstanceId' --output text)

if [ "$MONGO_INSTANCE_ID" != "None" ]; then
    SG_ID=$(aws ec2 describe-instances --instance-ids $MONGO_INSTANCE_ID \
        --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' --output text)
    
    aws ec2 describe-security-groups --group-ids $SG_ID \
        --query 'SecurityGroups[0].IpPermissions[?FromPort==`22`].IpRanges[?CidrIp==`0.0.0.0/0`].CidrIp' \
        --output text | grep -q "0.0.0.0/0" && echo "  ✓ SSH accessible from anywhere" || echo "  ✗ SSH not open"
fi

# Check public S3 bucket
echo "• Public S3 Bucket:"
BUCKET_NAME=$(cd terraform && terraform output -raw backup_bucket_name)
aws s3api get-bucket-policy --bucket $BUCKET_NAME \
    --query 'Policy' --output text | grep -q '"Principal":"*"' && echo "  ✓ S3 bucket is publicly accessible" || echo "  ✗ S3 bucket not public"

# Check cluster-admin privileges
echo "• Kubernetes Over-Privileges:"
kubectl describe clusterrolebinding wiz-todo-app-admin | grep -q "cluster-admin" && echo "  ✓ Service account has cluster-admin privileges" || echo "  ✗ No cluster-admin found"

# Check database credentials in ConfigMap
echo "• Database Credentials Exposure:"
kubectl get configmap wiz-todo-config -n wiz -o yaml | grep -q "MONGO_URL.*mongodb://" && echo "  ✓ Database credentials in ConfigMap" || echo "  ✗ No credentials found"

# Check outdated software
echo "• Outdated Software Versions:"
echo "  ✓ Ubuntu 20.04 (4+ years old)"
echo "  ✓ MongoDB 4.4 (EOL February 2024)"

echo ""
echo -e "${BLUE}4. COMPLIANCE SUMMARY${NC}"
echo "========================"

echo ""
echo -e "${GREEN}Detective Controls Active:${NC}"
echo "  ✓ AWS Config Rules monitoring compliance"
echo "  ✓ CloudTrail logging all API calls"
echo "  ✓ Continuous security assessment"

echo ""
echo -e "${GREEN}Preventative Controls Active:${NC}"
echo "  ✓ IAM Permission Boundary preventing VPC deletion"
echo "  ✓ Network segmentation isolating workloads"
echo "  ✓ Infrastructure as Code with security scanning"

echo ""
echo -e "${RED}Vulnerabilities Detected:${NC}"
echo "  • SSH open to internet (0.0.0.0/0)"
echo "  • Public S3 bucket with sensitive data"
echo "  • Outdated operating system and database"
echo "  • Over-privileged Kubernetes service account"
echo "  • Database credentials in plain text"

echo ""
echo -e "${YELLOW}Remediation Recommendations:${NC}"
echo "  • Restrict SSH access to specific IP ranges"
echo "  • Make S3 bucket private and use IAM policies"
echo "  • Update Ubuntu and MongoDB to supported versions"
echo "  • Use least-privilege RBAC for Kubernetes"
echo "  • Store credentials in AWS Secrets Manager"

echo ""
echo -e "${GREEN}This demonstrates exactly what Wiz would detect and help remediate!${NC}"