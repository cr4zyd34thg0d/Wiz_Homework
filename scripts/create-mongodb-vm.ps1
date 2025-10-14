# PowerShell script for creating MongoDB VM on Windows
# Manual MongoDB VM creation script for Wiz demo

$ErrorActionPreference = "Stop"

function Write-Log {
    param($Message, $Color = "White")
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

function Test-AWSConnection {
    Write-Log "Checking AWS connectivity..." "Blue"
    try {
        aws sts get-caller-identity | Out-Null
        Write-Log "✓ AWS credentials working" "Green"
    }
    catch {
        Write-Log "✗ AWS credentials not configured" "Red"
        exit 1
    }
}

function Get-NetworkInfo {
    Write-Log "Getting network information..." "Blue"
    
    # Get VPC ID
    $vpcId = aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*wiz-exercise*" --query 'Vpcs[0].VpcId' --output text --region us-east-1 2>$null
    if ($vpcId -eq "None" -or [string]::IsNullOrEmpty($vpcId)) {
        Write-Log "✗ VPC not found" "Red"
        exit 1
    }
    Write-Log "✓ VPC found: $vpcId" "Green"
    
    # Get public subnet ID
    $subnetId = aws ec2 describe-subnets --filters "Name=tag:Name,Values=*wiz-exercise*public*" --query 'Subnets[0].SubnetId' --output text --region us-east-1 2>$null
    if ($subnetId -eq "None" -or [string]::IsNullOrEmpty($subnetId)) {
        Write-Log "✗ Public subnet not found" "Red"
        exit 1
    }
    Write-Log "✓ Public subnet found: $subnetId" "Green"
    
    return @{
        VpcId = $vpcId
        SubnetId = $subnetId
    }
}

function New-SecurityGroup {
    param($VpcId)
    
    Write-Log "Creating MongoDB security group..." "Blue"
    
    # Check if security group already exists
    $sgId = aws ec2 describe-security-groups --filters "Name=group-name,Values=wiz-exercise-dev-mongodb-vm" --query 'SecurityGroups[0].GroupId' --output text --region us-east-1 2>$null
    
    if ($sgId -eq "None" -or [string]::IsNullOrEmpty($sgId)) {
        # Create new security group
        $sgId = aws ec2 create-security-group --group-name wiz-exercise-dev-mongodb-vm --description "MongoDB VM - INTENTIONALLY VULNERABLE FOR DEMO" --vpc-id $VpcId --region us-east-1 --query 'GroupId' --output text
        
        Write-Log "✓ Security group created: $sgId" "Green"
        
        # Add SSH rule (vulnerable - from anywhere for demo)
        aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 22 --cidr 0.0.0.0/0 --region us-east-1
        
        # Add MongoDB rule (from VPC)
        aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 27017 --cidr 10.0.0.0/16 --region us-east-1
        
        Write-Log "✓ Security group rules added" "Green"
    }
    else {
        Write-Log "✓ Security group already exists: $sgId" "Green"
    }
    
    return $sgId
}

function New-MongoDBVM {
    param($SecurityGroupId, $SubnetId)
    
    Write-Log "Creating MongoDB VM..." "Blue"
    
    # Check if VM already exists
    $existingInstance = aws ec2 describe-instances --filters "Name=tag:Name,Values=wiz-exercise-dev-mongodb" "Name=instance-state-name,Values=running,pending" --query 'Reservations[0].Instances[0].InstanceId' --output text --region us-east-1 2>$null
    
    if ($existingInstance -ne "None" -and -not [string]::IsNullOrEmpty($existingInstance)) {
        Write-Log "⚠ MongoDB VM already exists: $existingInstance" "Yellow"
        return
    }
    
    # Create user data script
    $userData = @"
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
  bindIp: 0.0.0.0

processManagement:
  fork: true
  pidFilePath: /var/run/mongodb/mongod.pid
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
    "password": "password123",
    "email": "admin@company.com",
    "role": "admin",
    "ssn": "123-45-6789",
    "credit_card": "4111-1111-1111-1111"
  }
])
MONGOJS

echo "MongoDB setup completed - VULNERABLE CONFIGURATION FOR DEMO" >> /var/log/mongodb-setup.log
"@
    
    # Save user data to temp file
    $tempFile = [System.IO.Path]::GetTempFileName()
    $userData | Out-File -FilePath $tempFile -Encoding UTF8
    
    # Launch the instance
    $instanceId = aws ec2 run-instances --image-id ami-0c02fb55956c7d316 --instance-type t3.micro --security-group-ids $SecurityGroupId --subnet-id $SubnetId --associate-public-ip-address --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=wiz-exercise-dev-mongodb},{Key=Project,Value=wiz-exercise-v4},{Key=Environment,Value=dev}]' --user-data file://$tempFile --region us-east-1 --query 'Instances[0].InstanceId' --output text
    
    Write-Log "✓ MongoDB VM created: $instanceId" "Green"
    
    # Wait for instance to be running
    Write-Log "Waiting for instance to be running..." "Blue"
    aws ec2 wait instance-running --instance-ids $instanceId --region us-east-1
    
    # Get public IP
    $publicIp = aws ec2 describe-instances --instance-ids $instanceId --query 'Reservations[0].Instances[0].PublicIpAddress' --output text --region us-east-1
    
    Write-Log "✓ MongoDB VM is running at: $publicIp" "Green"
    
    # Clean up temp file
    Remove-Item $tempFile -Force
    
    return $publicIp
}

# Main execution
Write-Log "Starting MongoDB VM creation for Wiz demo..." "Green"
Write-Host ""

Test-AWSConnection
$networkInfo = Get-NetworkInfo
$securityGroupId = New-SecurityGroup -VpcId $networkInfo.VpcId
$publicIp = New-MongoDBVM -SecurityGroupId $securityGroupId -SubnetId $networkInfo.SubnetId

Write-Host ""
Write-Log "MongoDB VM creation completed!" "Green"
Write-Log "⚠ WARNING: This VM is intentionally vulnerable for demo purposes" "Yellow"
Write-Host ""
Write-Log "Demo commands:" "Blue"
Write-Host "Connect to MongoDB: mongo --host $publicIp:27017"
Write-Host "Test vulnerability: mongo $publicIp:27017/todoapp --eval 'db.users.find()'"