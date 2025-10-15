#!/bin/bash

echo "🗑️ Cleaning up AWS resources to save money..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}1. Deleting EKS cluster (most expensive)...${NC}"
aws eks delete-cluster --name wiz-exercise-dev 2>/dev/null || echo "EKS cluster not found or already deleted"

echo -e "${YELLOW}2. Terminating EC2 instances...${NC}"
INSTANCE_IDS=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=*wiz-exercise*" "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[].InstanceId' --output text)
if [ -n "$INSTANCE_IDS" ]; then
    aws ec2 terminate-instances --instance-ids $INSTANCE_IDS
    echo "Terminated instances: $INSTANCE_IDS"
else
    echo "No running instances found"
fi

echo -e "${YELLOW}3. Deleting Load Balancers...${NC}"
# Delete ALBs
ALB_ARNS=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `wiz-exercise`)].LoadBalancerArn' --output text)
for arn in $ALB_ARNS; do
    aws elbv2 delete-load-balancer --load-balancer-arn $arn
    echo "Deleted ALB: $arn"
done

# Delete Classic ELBs
ELB_NAMES=$(aws elb describe-load-balancers --query 'LoadBalancerDescriptions[?contains(LoadBalancerName, `wiz-exercise`)].LoadBalancerName' --output text)
for name in $ELB_NAMES; do
    aws elb delete-load-balancer --load-balancer-name $name
    echo "Deleted ELB: $name"
done

echo -e "${YELLOW}4. Deleting NAT Gateways...${NC}"
NAT_IDS=$(aws ec2 describe-nat-gateways --filter "Name=tag:Name,Values=*wiz-exercise*" --query 'NatGateways[?State==`available`].NatGatewayId' --output text)
for nat_id in $NAT_IDS; do
    aws ec2 delete-nat-gateway --nat-gateway-id $nat_id
    echo "Deleted NAT Gateway: $nat_id"
done

echo -e "${YELLOW}5. Releasing Elastic IPs...${NC}"
EIP_ALLOCS=$(aws ec2 describe-addresses --query 'Addresses[?AssociationId==null].AllocationId' --output text)
for alloc in $EIP_ALLOCS; do
    aws ec2 release-address --allocation-id $alloc
    echo "Released EIP: $alloc"
done

echo -e "${YELLOW}6. Cleaning up S3 buckets...${NC}"
for bucket in $(aws s3 ls | grep wiz-exercise | awk '{print $3}'); do
    echo "Emptying bucket: $bucket"
    aws s3 rm s3://$bucket --recursive --quiet
    aws s3 rb s3://$bucket
    echo "Deleted bucket: $bucket"
done

echo -e "${YELLOW}7. Waiting for resources to be deleted before VPC cleanup...${NC}"
sleep 30

echo -e "${YELLOW}8. Deleting VPC and related resources...${NC}"
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=wiz-exercise-dev-vpc" --query 'Vpcs[0].VpcId' --output text 2>/dev/null)
if [ "$VPC_ID" != "None" ] && [ -n "$VPC_ID" ]; then
    # Delete security groups (except default)
    aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text | xargs -n1 aws ec2 delete-security-group --group-id 2>/dev/null || true
    
    # Delete subnets
    aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[].SubnetId' --output text | xargs -n1 aws ec2 delete-subnet --subnet-id 2>/dev/null || true
    
    # Delete internet gateway
    IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[0].InternetGatewayId' --output text 2>/dev/null)
    if [ "$IGW_ID" != "None" ] && [ -n "$IGW_ID" ]; then
        aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID 2>/dev/null || true
        aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID 2>/dev/null || true
    fi
    
    # Delete route tables (except main)
    aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' --output text | xargs -n1 aws ec2 delete-route-table --route-table-id 2>/dev/null || true
    
    # Finally delete VPC
    aws ec2 delete-vpc --vpc-id $VPC_ID 2>/dev/null && echo "Deleted VPC: $VPC_ID" || echo "VPC deletion failed (may have dependencies)"
fi

echo -e "${GREEN}✅ Cleanup complete! Check AWS console to verify all resources are deleted.${NC}"
echo -e "${YELLOW}💡 If some resources remain, wait a few minutes and run this script again.${NC}"