#!/bin/bash

# Verification script to ensure repository is ready for CloudLabs
echo "🔍 Verifying repository package for CloudLabs deployment..."

# Check required files exist
REQUIRED_FILES=(
    "README.md"
    "DEPLOYMENT_CHECKLIST.md"
    "terraform/main.tf"
    "terraform/variables.tf"
    "app/server.js"
    "app/Dockerfile"
    "app/package.json"
    "app/wizexercise.txt"
    "k8s/app/deployment.yaml"
    "k8s/app/service.yaml"
    "k8s/app/rbac.yaml"
    "scripts/test-deployment.sh"
    ".github/workflows/terraform-apply.yml"
    ".github/workflows/container-security.yml"
)

echo "📋 Checking required files..."
MISSING_FILES=0
for file in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        echo "✅ $file"
    else
        echo "❌ $file (MISSING)"
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
done

# Check wizexercise.txt content
echo ""
echo "📄 Checking wizexercise.txt content..."
if [[ -f "app/wizexercise.txt" ]]; then
    CONTENT=$(cat app/wizexercise.txt)
    if [[ "$CONTENT" == "Devon Diffie" ]]; then
        echo "✅ wizexercise.txt contains correct content: '$CONTENT'"
    else
        echo "❌ wizexercise.txt has wrong content: '$CONTENT' (should be 'Devon Diffie')"
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
fi

# Check for unwanted files
echo ""
echo "🧹 Checking for unwanted files..."
UNWANTED_PATTERNS=(
    "terraform.tfstate*"
    "*subnet*"
    "*ubnet*"
    "*sociate*"
    "*elbv2*"
    "*describe*"
)

UNWANTED_FOUND=0
for pattern in "${UNWANTED_PATTERNS[@]}"; do
    if find . -name "$pattern" -not -path "./.git/*" -not -name "*.tf" -not -name "*.md" | grep -q .; then
        echo "⚠️  Found unwanted files matching: $pattern"
        find . -name "$pattern" -not -path "./.git/*" -not -name "*.tf" -not -name "*.md"
        UNWANTED_FOUND=$((UNWANTED_FOUND + 1))
    fi
done

if [[ $UNWANTED_FOUND -eq 0 ]]; then
    echo "✅ No unwanted files found"
fi

# Check script permissions
echo ""
echo "🔧 Checking script permissions..."
find . -name "*.sh" -not -executable -not -path "./.git/*" | while read -r script; do
    echo "⚠️  Script not executable: $script"
    chmod +x "$script"
    echo "✅ Fixed permissions for: $script"
done

# Summary
echo ""
echo "📊 VERIFICATION SUMMARY"
echo "======================="
if [[ $MISSING_FILES -eq 0 ]]; then
    echo "✅ All required files present"
else
    echo "❌ $MISSING_FILES required files missing"
fi

if [[ $UNWANTED_FOUND -eq 0 ]]; then
    echo "✅ Repository is clean"
else
    echo "⚠️  $UNWANTED_FOUND types of unwanted files found"
fi

echo ""
if [[ $MISSING_FILES -eq 0 && $UNWANTED_FOUND -eq 0 ]]; then
    echo "🎉 Repository is READY for CloudLabs deployment!"
    echo ""
    echo "📋 Quick deployment test commands:"
    echo "cd terraform && terraform init && terraform plan"
    echo "kubectl apply -f k8s/app/ --dry-run=client"
else
    echo "⚠️  Repository needs attention before CloudLabs deployment"
    if [[ $UNWANTED_FOUND -gt 0 ]]; then
        echo "💡 Run ./cleanup-repo.sh to fix unwanted files"
    fi
fi