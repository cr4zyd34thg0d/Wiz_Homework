# Kubernetes Vulnerable Database Project Makefile
# Provides easy automation for the entire project lifecycle

.PHONY: help init terraform-init terraform-plan terraform-apply terraform-destroy k8s-setup k8s-deploy k8s-destroy setup-vulnerable-db test-connectivity test-security test-integration test cleanup-all

# Load environment variables
include .env
export

# Default target
help: ## Show this help message
	@echo "🚀 Kubernetes Vulnerable Database Project"
	@echo "=========================================="
	@echo ""
	@echo "Available commands:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Project initialization
init: ## Initialize the project (run this first)
	@echo "🔧 Initializing project..."
	@cp .env.example .env
	@echo "✅ Created .env file - please edit with your configuration"
	@echo "📝 Next steps:"
	@echo "   1. Edit .env file with your AWS credentials and preferences"
	@echo "   2. Run 'make terraform-init' to initialize Terraform"
	@echo "   3. Run 'make terraform-apply' to create infrastructure"

# Terraform commands
terraform-init: ## Initialize Terraform
	@echo "🏗️  Initializing Terraform..."
	@cd terraform && terraform init
	@echo "✅ Terraform initialized"

terraform-plan: ## Plan Terraform changes
	@echo "📋 Planning Terraform changes..."
	@cd terraform && terraform plan -var-file="../config/terraform.tfvars"
	@echo "✅ Terraform plan complete"

terraform-apply: ## Apply Terraform changes
	@echo "🚀 Applying Terraform changes..."
	@cd terraform && terraform apply -var-file="../config/terraform.tfvars" -auto-approve
	@echo "✅ Infrastructure deployed"
	@make update-kubeconfig

terraform-destroy: ## Destroy Terraform infrastructure
	@echo "💥 Destroying infrastructure..."
	@cd terraform && terraform destroy -var-file="../config/terraform.tfvars" -auto-approve
	@echo "✅ Infrastructure destroyed"

# Kubernetes commands
update-kubeconfig: ## Update kubeconfig for EKS cluster
	@echo "🔧 Updating kubeconfig..."
	@aws eks update-kubeconfig --region $(AWS_REGION) --name $(CLUSTER_NAME)
	@echo "✅ Kubeconfig updated"

k8s-setup: ## Setup Kubernetes prerequisites
	@echo "⚙️  Setting up Kubernetes prerequisites..."
	@kubectl apply -f k8s/namespace.yaml
	@kubectl apply -f k8s/configmap.yaml
	@echo "✅ Kubernetes setup complete"

k8s-deploy: ## Deploy applications to Kubernetes
	@echo "🚀 Deploying applications to Kubernetes..."
	@kubectl apply -f k8s/
	@echo "✅ Applications deployed"
	@make get-endpoints

k8s-destroy: ## Remove applications from Kubernetes
	@echo "💥 Removing applications from Kubernetes..."
	@kubectl delete -f k8s/ --ignore-not-found=true
	@echo "✅ Applications removed"

# Database setup
setup-vulnerable-db: ## Setup vulnerable database on EC2
	@echo "🗄️  Setting up vulnerable database..."
	@chmod +x scripts/setup-vulnerable-db.sh
	@./scripts/setup-vulnerable-db.sh
	@echo "✅ Vulnerable database setup complete"

# Testing commands
test-connectivity: ## Test connectivity between K8s and database
	@echo "🔗 Testing connectivity..."
	@chmod +x scripts/test-connectivity.sh
	@./scripts/test-connectivity.sh
	@echo "✅ Connectivity test complete"

test-security: ## Run security scans
	@echo "🔒 Running security scans..."
	@python3 tests/security-tests.py
	@echo "✅ Security scan complete"

test-integration: ## Run integration tests
	@echo "🧪 Running integration tests..."
	@python3 tests/integration-tests.py
	@echo "✅ Integration tests complete"

test: test-connectivity test-security test-integration ## Run all tests

# Monitoring
setup-monitoring: ## Setup monitoring stack
	@echo "📊 Setting up monitoring..."
	@kubectl apply -f monitoring/
	@echo "✅ Monitoring setup complete"

# Utility commands
get-endpoints: ## Get application endpoints
	@echo "🌐 Application Endpoints:"
	@echo "========================"
	@echo "EKS Cluster:"
	@kubectl get svc -A
	@echo ""
	@echo "Vulnerable Database:"
	@cd terraform && terraform output db_instance_public_ip
	@echo ""
	@echo "Grafana Dashboard:"
	@kubectl get svc grafana -n monitoring --no-headers | awk '{print "http://" $$4 ":3000"}'

logs: ## View application logs
	@echo "📋 Application Logs:"
	@kubectl logs -l app=$(APP_NAME) --tail=50

describe-cluster: ## Describe EKS cluster
	@echo "🔍 EKS Cluster Information:"
	@kubectl cluster-info
	@kubectl get nodes -o wide

# Security commands
scan-images: ## Scan container images for vulnerabilities
	@echo "🔍 Scanning container images..."
	@trivy image $(APP_IMAGE)
	@echo "✅ Image scan complete"

check-terraform: ## Run Terraform security checks
	@echo "🔒 Running Terraform security checks..."
	@checkov -d terraform/
	@echo "✅ Terraform security check complete"

# Cleanup commands
cleanup-k8s: ## Cleanup Kubernetes resources
	@echo "🧹 Cleaning up Kubernetes resources..."
	@kubectl delete -f k8s/ --ignore-not-found=true
	@kubectl delete -f monitoring/ --ignore-not-found=true
	@echo "✅ Kubernetes cleanup complete"

cleanup-terraform: ## Cleanup Terraform resources
	@echo "🧹 Cleaning up Terraform resources..."
	@cd terraform && terraform destroy -var-file="../config/terraform.tfvars" -auto-approve
	@echo "✅ Terraform cleanup complete"

cleanup-all: cleanup-k8s cleanup-terraform ## Cleanup everything
	@echo "✅ Complete cleanup finished"

# Development commands
dev-setup: ## Setup development environment
	@echo "💻 Setting up development environment..."
	@pip3 install -r requirements.txt
	@pre-commit install
	@echo "✅ Development environment ready"

format: ## Format code
	@echo "🎨 Formatting code..."
	@terraform fmt -recursive terraform/
	@black tests/
	@echo "✅ Code formatted"

validate: ## Validate configurations
	@echo "✅ Validating configurations..."
	@cd terraform && terraform validate
	@kubectl apply --dry-run=client -f k8s/
	@echo "✅ Validation complete"

# Documentation
docs: ## Generate documentation
	@echo "📚 Generating documentation..."
	@cd terraform && terraform-docs markdown . > ../docs/TERRAFORM.md
	@echo "✅ Documentation generated"

# Presentation
demo: ## Run demo sequence
	@echo "🎬 Running demo sequence..."
	@echo "1. Showing infrastructure..."
	@make describe-cluster
	@echo ""
	@echo "2. Showing applications..."
	@make get-endpoints
	@echo ""
	@echo "3. Testing connectivity..."
	@make test-connectivity
	@echo ""
	@echo "4. Showing monitoring..."
	@kubectl get pods -n monitoring
	@echo "✅ Demo sequence complete"

# CI/CD simulation
ci-test: ## Simulate CI/CD pipeline
	@echo "🔄 Simulating CI/CD pipeline..."
	@make validate
	@make test
	@make scan-images
	@make check-terraform
	@echo "✅ CI/CD simulation complete"

# Status check
status: ## Check overall project status
	@echo "📊 Project Status:"
	@echo "=================="
	@echo "Terraform State:"
	@cd terraform && terraform show -json | jq -r '.values.root_module.resources[] | select(.type == "aws_eks_cluster") | .values.name' 2>/dev/null || echo "No EKS cluster found"
	@echo ""
	@echo "Kubernetes Status:"
	@kubectl get nodes --no-headers 2>/dev/null | wc -l | xargs echo "Nodes:" || echo "Nodes: 0 (cluster not accessible)"
	@echo ""
	@echo "Applications:"
	@kubectl get pods -A --no-headers 2>/dev/null | wc -l | xargs echo "Pods:" || echo "Pods: 0"

# Quick start sequence
quick-start: init terraform-init terraform-apply k8s-setup k8s-deploy setup-vulnerable-db test ## Complete quick start sequence
	@echo "🎉 Quick start complete! Your environment is ready."
	@make get-endpoints