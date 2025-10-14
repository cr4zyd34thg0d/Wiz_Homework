#!/bin/bash

# Manual MongoDB VM creation script for Wiz demo
# This creates the MongoDB VM that Terraform failed to provision

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

# Check AWS connectivity
check_aws() {
    log "${BLUE}Checking AWS connectivity...${NC}"
    if ! aws sts get-caller-identity &> /dev/null; then
        log "${RED}✗ AWS credentials not configured${NC}"
        exit 1
    fi
    log "${GREEN}✓ AWS credentials working${NC}"
}

# Get VPC and subnet information
get_network_info() {
    log "${BLUE}Getting network information...${NC}"
    
    # Get VPC ID
    VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*wiz-exercise*" --query 'Vpcs[0].VpcId' --output text --region us-east-1 2>/dev/null)
    if [ "$VPC_ID" = "None" ] || [ -z "$VPC_ID" ]; then
        log "${RED}✗ VPC not found${NC}"
        exit 1
    fi
    log "${GREEN}✓ VPC found: $VPC_ID${NC}"
    
    # Get public subnet ID
    SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=*wiz-exercise*public*" --query 'Subnets[0].SubnetId' --output text --region us-east-1 2>/dev/null)
    if [ "$SUBNET_ID" = "None" ] || [ -z "$SUBNET_ID" ]; then
        log "${RED}✗ Public subnet not found${NC}"
        exit 1
    fi
    log "${GREEN}✓ Public subnet found: $SUBNET_ID${NC}"
}

# Create security group for MongoDB
create_security_group() {
    log "${BLUE}Creating MongoDB security group...${NC}"
    
    # Check if security group already exists
    SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=wiz-exercise-dev-mongodb-vm" --query 'SecurityGroups[0].GroupId' --output text --region us-east-1 2>/dev/null)
    
    if [ "$SG_ID" = "None" ] || [ -z "$SG_ID" ]; then
        # Create new security group
        SG_ID=$(aws ec2 create-security-group \
            --group-name wiz-exercise-dev-mongodb-vm \
            --description "MongoDB VM - INTENTIONALLY VULNERABLE FOR DEMO" \
            --vpc-id $VPC_ID \
            --region us-east-1 \
            --query 'GroupId' --output text)
        
        log "${GREEN}✓ Security group created: $SG_ID${NC}"
        
        # Add SSH rule (vulnerable - from anywhere for demo)
        aws ec2 authorize-security-group-ingress \
            --group-id $SG_ID \
            --protocol tcp \
            --port 22 \
            --cidr 0.0.0.0/0 \
            --region us-east-1
        
        # Add MongoDB rule (from VPC)
        aws ec2 authorize-security-group-ingress \
            --group-id $SG_ID \
            --protocol tcp \
            --port 27017 \
            --cidr 10.0.0.0/16 \
            --region us-east-1
        
        log "${GREEN}✓ Security group rules added${NC}"
    else
        log "${GREEN}✓ Security group already exists: $SG_ID${NC}"
    fi
}

# Create MongoDB setup user data script
create_user_data() {
    cat > /tmp/mongodb-setup.sh << 'EOF'
#!/bin/bash
# MongoDB setup script - INTENTIONALLY VULNERABLE FOR DEMO

# Update system
apt-get update -y

# Install MongoDB
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list
apt-get update -y
apt-get install -y mongodb-org

# VULNERABLE CONFIG: No authentication, bind to all interfaces
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
  bindIp: 0.0.0.0  # VULNERABLE: Binds to all interfaces

processManagement:
  fork: true
  pidFilePath: /var/run/mongodb/mongod.pid

# NO SECURITY SECTION - VULNERABLE: No authentication required
MONGOCONF

# Start MongoDB
systemctl enable mongod
systemctl start mongod

# Create sample vulnerable data
sleep 10
mongo << 'MONGOJS'
use todoapp
db.users.insertMany([
  {
    "username": "admin",
    "password": "password123",  // VULNERABLE: Plain text password
    "email": "admin@company.com",
    "role": "admin",
    "ssn": "123-45-6789",      // VULNERABLE: PII in database
    "credit_card": "4111-1111-1111-1111"  // VULNERABLE: Sensitive data
  },
  {
    "username": "john.doe",
    "password": "john123",
    "email": "john@company.com",
    "role": "user",
    "ssn": "987-65-4321",
    "salary": 75000
  }
])

db.todos.insertMany([
  {"user": "admin", "task": "Review security policies", "completed": false},
  {"user": "admin", "task": "Update database passwords", "completed": false},
  {"user": "john.doe", "task": "Complete project", "completed": true}
])

db.secrets.insertOne({
  "api_key": "sk-1234567890abcdef",  // VULNERABLE: API keys in database
  "aws_access_key": "AKIA1234567890ABCDEF",
  "aws_secret_key": "abcdef1234567890abcdef1234567890abcdef12"
})
MONGOJS

# Log completion
echo "MongoDB setup completed - VULNERABLE CONFIGURATION FOR DEMO" >> /var/log/mongodb-setup.log
EOF
}

# Create the MongoDB VM
create_mongodb_vm() {
    log "${BLUE}Creating MongoDB VM...${NC}"
    
    # Check if VM already exists
    EXISTING_INSTANCE=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=wiz-exercise-dev-mongodb" "Name=instance-state-name,Values=running,pending" \
        --query 'Reservations[0].Instances[0].InstanceId' \
        --output text --region us-east-1 2>/dev/null)
    
    if [ "$EXISTING_INSTANCE" != "None" ] && [ -n "$EXISTING_INSTANCE" ]; then
        log "${YELLOW}⚠ MongoDB VM already exists: $EXISTING_INSTANCE${NC}"
        return 0
    fi
    
    # Create user data script
    create_user_data
    
    # Launch the instance
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id ami-0c02fb55956c7d316 \
        --instance-type t3.micro \
        --security-group-ids $SG_ID \
        --subnet-id $SUBNET_ID \
        --associate-public-ip-address \
        --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=wiz-exercise-dev-mongodb},{Key=Project,Value=wiz-exercise-v4},{Key=Environment,Value=dev}]' \
        --user-data file:///tmp/mongodb-setup.sh \
        --region us-east-1 \
        --query 'Instances[0].InstanceId' --output text)
    
    log "${GREEN}✓ MongoDB VM created: $INSTANCE_ID${NC}"
    
    # Wait for instance to be running
    log "${BLUE}Waiting for instance to be running...${NC}"
    aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region us-east-1
    
    # Get public IP
    PUBLIC_IP=$(aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text --region us-east-1)
    
    log "${GREEN}✓ MongoDB VM is running at: $PUBLIC_IP${NC}"
    
    # Clean up temp file
    rm -f /tmp/mongodb-setup.sh
}

# Main function
main() {
    log "${GREEN}Starting MongoDB VM creation for Wiz demo...${NC}"
    echo ""
    
    check_aws
    get_network_info
    create_security_group
    create_mongodb_vm
    
    echo ""
    log "${GREEN}MongoDB VM creation completed!${NC}"
    log "${YELLOW}⚠ WARNING: This VM is intentionally vulnerable for demo purposes${NC}"
    echo ""
    log "${BLUE}Demo commands:${NC}"
    echo "Connect to MongoDB: mongo --host $PUBLIC_IP:27017"
    echo "SSH to VM: ssh -i your-keypair.pem ubuntu@$PUBLIC_IP"
    echo "Test vulnerability: mongo $PUBLIC_IP:27017/todoapp --eval 'db.users.find()'"
}

main "$@"