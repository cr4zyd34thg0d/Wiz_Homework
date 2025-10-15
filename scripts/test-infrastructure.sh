#!/bin/bash
# Infrastructure Validation Tests for Wiz Demo
# This script validates that all infrastructure components are working correctly

set -e

echo "Wiz Demo - Infrastructure Validation Tests"
echo "============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "\n${YELLOW}Testing: $test_name${NC}"
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}PASS: $test_name${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}FAIL: $test_name${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Function to run test with output
run_test_with_output() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "\n${YELLOW}Testing: $test_name${NC}"
    
    if result=$(eval "$test_command" 2>&1); then
        echo -e "${GREEN}PASS: $test_name${NC}"
        echo "$result"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}FAIL: $test_name${NC}"
        echo "$result"
        ((TESTS_FAILED++))
        return 1
    fi
}

echo ""
echo "1. INFRASTRUCTURE VALIDATION TESTS"
echo "======================================"

# Test 1: EKS Cluster Access
run_test "EKS cluster is accessible via kubectl" "kubectl get nodes"

# Test 2: MongoDB VM is running
run_test "MongoDB VM is running" "aws ec2 describe-instances --instance-ids \$(cd terraform && terraform output -raw mongodb_private_ip | xargs -I {} aws ec2 describe-instances --filters 'Name=private-ip-address,Values={}' --query 'Reservations[0].Instances[0].InstanceId' --output text) --query 'Reservations[0].Instances[0].State.Name' --output text | grep -q running"

# Test 3: S3 buckets exist
run_test "Backup S3 bucket exists" "aws s3 ls s3://\$(cd terraform && terraform output -raw backup_bucket_name)"

# Test 4: MongoDB connectivity from cluster
run_test "MongoDB port 27017 is accessible from cluster" "kubectl exec -n wiz deployment/wiz-todo-app -- nc -zv \$(cd terraform && terraform output -raw mongodb_private_ip) 27017"

echo ""
echo "2. APPLICATION CONNECTIVITY TESTS"
echo "===================================="

# Test 5: App can connect to MongoDB
run_test_with_output "App connects to MongoDB successfully" "kubectl exec -n wiz deployment/wiz-todo-app -- wget -qO- http://localhost:3000/health | grep -q 'connected'"

# Test 6: App responds to health checks
run_test "App responds to health endpoint" "kubectl exec -n wiz deployment/wiz-todo-app -- wget -qO- http://localhost:3000/health"

# Test 7: wizexercise.txt file exists
run_test_with_output "wizexercise.txt file is accessible in container" "kubectl exec -n wiz deployment/wiz-todo-app -- cat /app/wizexercise.txt"

# Test 8: MongoDB data is accessible
run_test "MongoDB data is accessible via API" "kubectl exec -n wiz deployment/wiz-todo-app -- wget -qO- http://localhost:3000/api/todos"

echo ""
echo "3. END-TO-END DEPLOYMENT TESTS"
echo "================================="

# Test 9: Load balancer is created
run_test "Load balancer service is created" "kubectl get service wiz-todo-service -n wiz -o jsonpath='{.spec.type}' | grep -q LoadBalancer"

# Test 10: External IP is assigned
run_test "External IP is assigned to load balancer" "kubectl get service wiz-todo-service -n wiz -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' | grep -q elb.amazonaws.com"

# Test 11: External endpoint is accessible
EXTERNAL_URL=$(kubectl get service wiz-todo-service -n wiz -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
if [ ! -z "$EXTERNAL_URL" ]; then
    run_test "External endpoint is accessible" "curl -s http://$EXTERNAL_URL/health | grep -q 'connected'"
else
    echo -e "${RED}FAIL: External endpoint test - No external URL found${NC}"
    ((TESTS_FAILED++))
fi

echo ""
echo "4. SECURITY VULNERABILITY TESTS"
echo "=================================="

# Test 12: SSH is open to world (vulnerability check)
run_test "SSH vulnerability exists (0.0.0.0/0 access)" "aws ec2 describe-security-groups --group-ids \$(aws ec2 describe-instances --instance-ids \$(cd terraform && terraform output -raw mongodb_private_ip | xargs -I {} aws ec2 describe-instances --filters 'Name=private-ip-address,Values={}' --query 'Reservations[0].Instances[0].InstanceId' --output text) --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' --output text) --query 'SecurityGroups[0].IpPermissions[?FromPort==\`22\`].IpRanges[?CidrIp==\`0.0.0.0/0\`]' --output text | grep -q 0.0.0.0/0"

# Test 13: Public S3 bucket exists (vulnerability)
run_test "Public S3 bucket vulnerability exists" "aws s3api get-bucket-policy --bucket \$(cd terraform && terraform output -raw backup_bucket_name) | grep -q 'Principal.*\\*'"

# Test 14: Cluster-admin privileges (vulnerability)
run_test "Cluster-admin service account vulnerability exists" "kubectl describe clusterrolebinding wiz-todo-app-admin | grep -q cluster-admin"

# Test 15: Database credentials in ConfigMap (vulnerability)
run_test "Database credentials in ConfigMap vulnerability exists" "kubectl get configmap wiz-todo-config -n wiz -o yaml | grep -q 'MONGO_URL.*mongodb://'"

echo ""
echo "TEST SUMMARY"
echo "==============="
echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}ALL TESTS PASSED! Infrastructure is ready for Wiz demo.${NC}"
    exit 0
else
    echo -e "\n${RED}WARNING: Some tests failed. Please check the infrastructure.${NC}"
    exit 1
fi