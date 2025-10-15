# CloudLabs Setup Guide

## **AWS OIDC Setup for GitHub Actions**

### **1. Create OIDC Identity Provider**
```bash
aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### **2. Create IAM Role for GitHub Actions**
```bash
# Create trust policy file
cat > github-trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::ACCOUNT-ID:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
                    "token.actions.githubusercontent.com:sub": "repo:YOUR-GITHUB-USERNAME/Wiz_Homework:ref:refs/heads/main"
                }
            }
        }
    ]
}
EOF

# Create the role
aws iam create-role \
    --role-name github-actions-role \
    --assume-role-policy-document file://github-trust-policy.json

# Attach admin policy (for demo purposes)
aws iam attach-role-policy \
    --role-name github-actions-role \
    --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

### **3. GitHub Repository Secrets**
Add these in GitHub → Settings → Secrets and Variables → Actions:

- `AWS_REGION`: `us-east-1`
- `AWS_ROLE_TO_ASSUME`: `arn:aws:iam::ACCOUNT-ID:role/github-actions-role`

### **4. Test Deployment**
1. Push code to GitHub
2. Go to Actions tab
3. Run "Terraform Apply" workflow manually
4. Wait ~15 minutes for complete deployment
5. Run validation: `./validate-assignment.sh`

## **Alternative: Manual Deployment**
If OIDC setup is complex, you can deploy manually in CloudLabs:

```bash
# 1. Clone repository
git clone https://github.com/YOUR-USERNAME/Wiz_Homework.git
cd Wiz_Homework

# 2. Deploy infrastructure
cd terraform
terraform init
terraform apply

# 3. Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name wiz-exercise-dev

# 4. Deploy application
kubectl apply -f k8s/app/
kubectl create service loadbalancer wiz-todo-app --tcp=80:3000

# 5. Validate
./validate-assignment.sh
```

## **Demo Strategy**
1. **Show working application** (LoadBalancer URL)
2. **Demonstrate security vulnerabilities**
3. **Explain CI/CD pipeline** (show GitHub Actions)
4. **Highlight DevSecOps integration**