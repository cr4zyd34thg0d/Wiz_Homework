#!/bin/bash

# Create a new MongoDB instance with simpler setup
aws ec2 run-instances \
  --image-id ami-0c02fb55956c7d316 \
  --instance-type t3.micro \
  --key-name wiz-exercise-demo-keypair \
  --security-group-ids sg-0b3c4e5e68a39a087 \
  --subnet-id subnet-02e914c580d3e6577 \
  --associate-public-ip-address \
  --user-data file://simple-mongodb-userdata.sh \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=wiz-exercise-demo-mongodb-simple}]'