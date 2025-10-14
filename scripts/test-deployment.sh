#!/bin/bash

# Simple deployment test script
# Tests that everything is working for the Wiz demo

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

# Test AWS connectivity
test_aws() {
    log "${BLUE}Testing AWS connection...${NC}"
    if aws sts get-caller-identity &> /dev/null; then
        log "${GREEN}✓ AWS credentials working${NC}"
    else
        log "${RED}✗ AWS credentials not configured${NC}"
        exit 1
    fi
}

# Test Terraform infrastructure
test_infrastructure() {
    log "${BLUE}Testing infrastructure...${NC}"
    
    # Check if VPC exists
    VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=wiz-exercise-dev-vpc" --query 'Vpcs[0].VpcId' --output text --region us-east-1 2>/dev/null)
    if [ "$VPC_ID" != "None" ] && [ "$VPC_ID" != "" ]; then
        log "${GREEN}✓ VPC exists: $VPC_ID${NC}"
    else
        log "${RED}✗ VPC not found${NC}"
        return 1
    fi
    
    # Check if EKS cluster exists
    if aws eks describe-cluster --name wiz-exercise-dev --region us-east-1 &> /dev/null; then
        log "${GREEN}✓ EKS cluster exists${NC}"
    else
        log "${RED}✗ EKS cluster not found${NC}"
        return 1
    fi
    
    # Check if MongoDB VM exists
    MONGODB_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=wiz-exercise-dev-mongodb" "Name=instance-state-name,Values=running" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text --region us-east-1 2>/dev/null)
    if [ "$MONGODB_IP" != "None" ] && [ "$MONGODB_IP" != "" ]; then
        log "${GREEN}✓ MongoDB VM running: $MONGODB_IP${NC}"
    else
        log "${RED}✗ MongoDB VM not found${NC}"
        return 1
    fi
}

# Test Kubernetes connectivity
test_kubernetes() {
    log "${BLUE}Testing Kubernetes...${NC}"
    
    # Test kubectl connection
    if kubectl cluster-info &> /dev/null; then
        log "${GREEN}✓ kubectl connected to cluster${NC}"
    else
        log "${RED}✗ kubectl not connected${NC}"
        log "${YELLOW}Run: aws eks update-kubeconfig --region us-east-1 --name wiz-exercise-dev${NC}"
        return 1
    fi
    
    # Check if pods are running
    POD_COUNT=$(kubectl get pods -l app=wiz-todo-app --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
    if [ "$POD_COUNT" -gt 0 ]; then
        log "${GREEN}✓ Application pods running ($POD_COUNT)${NC}"
    else
        log "${RED}✗ No application pods running${NC}"
        return 1
    fi
}

# Test application functionality
test_application() {
    log "${BLUE}Testing application...${NC}"
    
    # Get ALB DNS
    ALB_DNS=$(kubectl get ingress wiz-todo-app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
    if [ -n "$ALB_DNS" ] && [ "$ALB_DNS" != "null" ]; then
        log "${GREEN}✓ ALB DNS: $ALB_DNS${NC}"
        
        # Test health endpoint
        if curl -f -s "http://$ALB_DNS/health" > /dev/null 2>&1; then
            log "${GREEN}✓ Application health check passed${NC}"
        else
            log "${YELLOW}⚠ Application health check failed (may still be starting)${NC}"
        fi
    else
        log "${YELLOW}⚠ ALB DNS not available yet${NC}"
    fi
    
    # Test wizexercise.txt file
    POD_NAME=$(kubectl get pods -l app=wiz-todo-app --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [ -n "$POD_NAME" ]; then
        FILE_CONTENT=$(kubectl exec "$POD_NAME" -- cat /app/wizexercise.txt 2>/dev/null)
        if [ "$FILE_CONTENT" = "Devon Diffie" ]; then
            log "${GREEN}✓ wizexercise.txt file correct${NC}"
        else
            log "${RED}✗ wizexercise.txt file incorrect or missing${NC}"
        fi
    fi
}

# Test security vulnerabilities (for demo)
test_vulnerabilities() {
    log "${BLUE}Testing security vulnerabilities (for demo)...${NC}"
    
    # Test RBAC over-privileges
    if kubectl auth can-i create nodes --as=system:serviceaccount:default:wiz-todo-app-sa 2>/dev/null | grep -q "yes"; then
        log "${YELLOW}⚠ VULNERABILITY: Service account has cluster-admin privileges${NC}"
    else
        log "${GREEN}✓ Service account properly restricted${NC}"
    fi
    
    # Test public S3 bucket
    BACKUP_BUCKET=$(aws s3api list-buckets --query "Buckets[?contains(Name, 'wiz-exercise-dev-backup')].Name" --output text --region us-east-1 2>/dev/null)
    if [ -n "$BACKUP_BUCKET" ]; then
        if aws s3 ls "s3://$BACKUP_BUCKET" &> /dev/null; then
            log "${YELLOW}⚠ VULNERABILITY: S3 bucket is publicly accessible${NC}"
        else
            log "${GREEN}✓ S3 bucket properly secured${NC}"
        fi
    fi
}

# Test security controls
test_security_controls() {
    log "${BLUE}Testing security controls...${NC}"
    
    # Test CloudTrail
    if aws cloudtrail get-trail-status --name wiz-exercise-dev-cloudtrail --region us-east-1 &> /dev/null; then
        log "${GREEN}✓ CloudTrail configured${NC}"
    else
        log "${YELLOW}⚠ CloudTrail not found${NC}"
    fi
    
    # Test AWS Config
    if aws configservice get-compliance-summary --region us-east-1 &> /dev/null; then
        log "${GREEN}✓ AWS Config enabled${NC}"
    else
        log "${YELLOW}⚠ AWS Config not configured${NC}"
    fi
}

# Main function
main() {
    log "${GREEN}Starting Wiz Exercise deployment test...${NC}"
    echo ""
    
    test_aws
    test_infrastructure
    test_kubernetes
    test_application
    test_vulnerabilities
    test_security_controls
    
    echo ""
    log "${GREEN}Test completed!${NC}"
    
    # Show demo commands
    echo ""
    log "${BLUE}Demo commands:${NC}"
    echo "Application URL: http://$ALB_DNS"
    echo "Test RBAC vulnerability: kubectl auth can-i --list --as=system:serviceaccount:default:wiz-todo-app-sa"
    echo "Show public S3 bucket: aws s3 ls s3://$BACKUP_BUCKET/"
    echo "SSH to MongoDB: ssh -i wiz-exercise-keypair.pem ubuntu@$MONGODB_IP"
}

main "$@"