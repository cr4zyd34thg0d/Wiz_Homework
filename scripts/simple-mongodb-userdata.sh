#!/bin/bash
set -x
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting MongoDB setup..."

# Update system
apt-get update -y

# Install MongoDB (simple version)
apt-get install -y mongodb

# Start MongoDB
systemctl start mongodb
systemctl enable mongodb

# Wait for MongoDB to start
sleep 10

# Create simple database without authentication for demo
mongo << 'EOF'
use todoapp
db.todos.insertMany([
  {"task": "Review security policies", "completed": false, "user": "admin"},
  {"task": "Update database passwords", "completed": false, "user": "admin"},
  {"task": "Complete Wiz demo", "completed": true, "user": "devon"}
])

db.users.insertMany([
  {"username": "admin", "email": "admin@company.com", "role": "admin"},
  {"username": "devon", "email": "devon@company.com", "role": "user"}
])
EOF

echo "MongoDB setup complete!"

# Test MongoDB
mongo --eval "db.adminCommand('listCollections')" todoapp

echo "User data script finished!"