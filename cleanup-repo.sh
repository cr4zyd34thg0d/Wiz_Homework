#!/bin/bash

# Cleanup script to prepare repository for CloudLabs deployment
echo "🧹 Cleaning up repository for CloudLabs deployment..."

# Remove terraform state files (these shouldn't be in git anyway)
echo "Removing Terraform state files..."
find . -name "terraform.tfstate*" -delete
find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true

# Remove any accidentally created files with weird names
echo "Removing accidentally created files..."
find . -name "*subnet*" -not -path "./.git/*" -not -name "*.tf" -not -name "*.md" -delete 2>/dev/null || true
find . -name "*ubnet*" -not -path "./.git/*" -delete 2>/dev/null || true
find . -name "*sociate*" -not -path "./.git/*" -delete 2>/dev/null || true
find . -name "*elbv2*" -not -path "./.git/*" -delete 2>/dev/null || true
find . -name "*ec2 describe*" -not -path "./.git/*" -delete 2>/dev/null || true
find . -name "*restart*" -not -path "./.git/*" -delete 2>/dev/null || true
find . -name "*ting*" -not -path "./.git/*" -delete 2>/dev/null || true
find . -name "*sudo apt*" -not -path "./.git/*" -delete 2>/dev/null || true

# Remove any files that look like command fragments
find . -type f -name "*describe*" -not -path "./.git/*" -delete 2>/dev/null || true
find . -type f -name "*query*" -not -path "./.git/*" -delete 2>/dev/null || true

# Clean up k8s directory
echo "Cleaning up k8s directory..."
find k8s/ -type f -not -name "*.yaml" -not -name "*.yml" -not -name "*.sh" -delete 2>/dev/null || true

# Make sure all shell scripts are executable
echo "Making shell scripts executable..."
find . -name "*.sh" -exec chmod +x {} \;

# Show what's left
echo "✅ Repository cleaned up!"
echo "📁 Current structure:"
find . -type f -not -path "./.git/*" | head -20

echo ""
echo "🚀 Repository is ready for CloudLabs deployment!"
echo "📋 Next steps:"
echo "1. git add ."
echo "2. git commit -m 'Clean repository for CloudLabs deployment'"
echo "3. git push origin main"