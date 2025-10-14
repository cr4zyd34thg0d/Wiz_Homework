#!/bin/bash

# Get SSH private key from Terraform output
# Usage: ./get-ssh-key.sh

set -e

echo "🔑 Retrieving SSH private key from Terraform..."

cd terraform

# Get the private key
terraform output -raw ssh_private_key > ../wiz-exercise-keypair.pem

# Set proper permissions
chmod 400 ../wiz-exercise-keypair.pem

echo "✅ SSH key saved to wiz-exercise-keypair.pem"
echo "📝 Usage: ssh -i wiz-exercise-keypair.pem ubuntu@<mongodb-vm-ip>"

# Get the MongoDB VM IP
MONGO_IP=$(terraform output -raw mongodb_public_ip)
echo "🖥️  MongoDB VM IP: $MONGO_IP"
echo "🔗 SSH command: ssh -i wiz-exercise-keypair.pem ubuntu@$MONGO_IP"