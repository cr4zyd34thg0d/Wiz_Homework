#!/bin/bash

# Wiz Security Demo Script
# Demonstrates common cloud security vulnerabilities that Wiz detects

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

log() {
    echo -e "[$(date '+%H:%M:%S')] $1"
}

header() {
    echo ""
    echo -e "${PURPLE}================================================${NC}"
    echo -e "${PURPLE} $1${NC}"
    echo -e "${PURPLE}================================================${NC}"
    echo ""
}

# Demo 1: RBAC Over-Privilege (CRITICAL)
demo_rbac_vulnerability() {
    header "🚨 CRITICAL: Kubernetes RBAC Over-Privilege"
    
    log "${RED}Service Account has cluster-admin privileges!${NC}"
    log "${BLUE}This allows complete cluster takeover...${NC}"
    echo ""
    
    echo "Service account permissions:"
    kubectl auth can-i --list --as=system:serviceaccount:default:wiz-todo-app-sa | head -15
    
    echo ""
    log "${YELLOW}Impact: An attacker with pod access can:${NC}"
    echo "  • Create/delete any resources (*.*)"
    echo "  • Access all secrets and configmaps"
    echo "  • Escalate to cluster administrator"
    echo "  • Deploy malicious workloads"
    
    echo ""
    log "${GREEN}Wiz Detection: Excessive Kubernetes permissions${NC}"
}

# Demo 2: Network Security Issues
demo_network_vulnerabilities() {
    header "🚨 HIGH: Network Security Misconfigurations"
    
    log "${RED}MongoDB VM exposed to internet!${NC}"
    echo ""
    
    # Show security group allowing SSH from anywhere
    echo "Security group rules (SSH from 0.0.0.0/0):"
    aws ec2 describe-security-groups \
        --filters "Name=group-name,Values=wiz-exercise-dev-mongodb-vm" \
        --query 'SecurityGroups[0].IpPermissions[?FromPort==`22`]' \
        --output table
    
    echo ""
    log "${YELLOW}Impact: SSH brute force attacks possible${NC}"
    echo "  • VM accessible from entire internet"
    echo "  • No IP restrictions or VPN requirement"
    echo "  • Potential for lateral movement"
    
    echo ""
    log "${GREEN}Wiz Detection: Overly permissive security groups${NC}"
}

# Demo 3: Container Vulnerabilities
demo_container_vulnerabilities() {
    header "🚨 HIGH: Container Security Issues"
    
    log "${RED}Outdated base images with known CVEs!${NC}"
    echo ""
    
    echo "Container components:"
    echo "  • Node.js 16.14.0 (Released: Feb 2022 - 2+ years old)"
    echo "  • Alpine Linux 3.15 (Released: Nov 2021 - 3+ years old)"
    echo "  • Multiple npm packages with known vulnerabilities"
    
    echo ""
    log "${YELLOW}Impact: Known exploitable vulnerabilities${NC}"
    echo "  • Remote code execution possible"
    echo "  • Privilege escalation vectors"
    echo "  • Supply chain attack surface"
    
    echo ""
    log "${GREEN}Wiz Detection: Vulnerable container images${NC}"
    log "${BLUE}Our CI/CD now includes Trivy scanning to catch these!${NC}"
}

# Demo 4: Data Exposure Risks
demo_data_exposure() {
    header "🚨 MEDIUM: Data Exposure Risks"
    
    log "${RED}S3 buckets for database backups exist${NC}"
    echo ""
    
    echo "S3 buckets in account:"
    aws s3 ls | grep wiz-exercise || echo "No buckets found (may be secured)"
    
    echo ""
    log "${YELLOW}Impact: Potential data exposure${NC}"
    echo "  • Database backups may contain PII"
    echo "  • Misconfigured bucket policies risk"
    echo "  • Compliance violations possible"
    
    echo ""
    log "${GREEN}Wiz Detection: S3 bucket misconfigurations${NC}"
}

# Demo 5: Infrastructure Status
demo_infrastructure_status() {
    header "✅ Infrastructure Status (What's Working)"
    
    log "${GREEN}Deployed Infrastructure:${NC}"
    
    # VPC
    VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*wiz-exercise*" --query 'Vpcs[0].VpcId' --output text 2>/dev/null)
    echo "  • VPC: $VPC_ID"
    
    # EKS Cluster
    echo "  • EKS Cluster: wiz-exercise-dev"
    
    # Application Pods
    POD_COUNT=$(kubectl get pods -l app=wiz-todo-app --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
    echo "  • Application Pods: $POD_COUNT running"
    
    # MongoDB VM
    MONGODB_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=wiz-exercise-dev-mongodb" "Name=instance-state-name,Values=running" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text 2>/dev/null)
    echo "  • MongoDB VM: $MONGODB_IP"
    
    echo ""
    log "${BLUE}Application Details:${NC}"
    kubectl get pods -l app=wiz-todo-app -o wide
}

# Demo 6: Security Controls Implemented
demo_security_controls() {
    header "🛡️ Security Controls (Defense in Depth)"
    
    log "${GREEN}Detective Controls:${NC}"
    echo "  • CloudTrail: Logging all API calls"
    echo "  • AWS Config: Compliance monitoring"
    echo "  • Container Scanning: Trivy in CI/CD"
    echo "  • Infrastructure Scanning: TfSec"
    
    echo ""
    log "${GREEN}Preventative Controls:${NC}"
    echo "  • Network Segmentation: Private subnets for EKS"
    echo "  • IAM Policies: Deny critical operations"
    echo "  • GitHub OIDC: No long-term AWS keys"
    
    echo ""
    log "${BLUE}DevSecOps Integration:${NC}"
    echo "  • Security scanning in CI/CD pipeline"
    echo "  • Infrastructure as Code"
    echo "  • Automated vulnerability detection"
}

# Main demo function
main() {
    log "${GREEN}🎯 Starting Wiz Security Demonstration${NC}"
    log "${BLUE}Showcasing common cloud misconfigurations...${NC}"
    
    demo_rbac_vulnerability
    demo_network_vulnerabilities
    demo_container_vulnerabilities
    demo_data_exposure
    demo_infrastructure_status
    demo_security_controls
    
    header "🎉 Demo Complete!"
    log "${GREEN}Key Takeaways:${NC}"
    echo "  • Multiple critical vulnerabilities detected"
    echo "  • Real-world attack vectors demonstrated"
    echo "  • Security controls provide defense in depth"
    echo "  • Wiz would detect and prioritize these issues"
    
    echo ""
    log "${PURPLE}Questions for Discussion:${NC}"
    echo "  • How would Wiz prioritize these vulnerabilities?"
    echo "  • What's the blast radius of the RBAC issue?"
    echo "  • How do we balance security vs. development velocity?"
}

main "$@"