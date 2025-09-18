#!/bin/bash

# OCI Terraform Infrastructure Deployment Script
# This script deploys OKE cluster with ArgoCD using Terraform

set -e

echo "🚀 Starting OCI Infrastructure Deployment..."

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo "❌ terraform.tfvars file not found!"
    echo "📝 Please copy terraform.tfvars.example to terraform.tfvars and fill in your values:"
    echo "   cp terraform.tfvars.example terraform.tfvars"
    echo "   # Edit terraform.tfvars with your OCI configuration"
    exit 1
fi

# Check if OCI CLI is installed
if ! command -v oci &> /dev/null; then
    echo "❌ OCI CLI is not installed!"
    echo "📥 Please install OCI CLI: https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm"
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed!"
    echo "📥 Please install Terraform: https://www.terraform.io/downloads"
    exit 1
fi

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Plan Terraform deployment
echo "📋 Planning Terraform deployment..."
terraform plan -out=tfplan

# Ask for confirmation
echo ""
echo "⚠️  This will create the following resources:"
echo "   - OCI VCN with subnets and gateways"
echo "   - OKE Kubernetes cluster with node pool"
echo "   - OCI Container Registry repositories"
echo "   - OCI Vault with secrets"
echo "   - OCI Storage resources (Block Volume, File System, Object Storage)"
echo "   - ArgoCD deployment with applications"
echo ""
read -p "🤔 Do you want to proceed? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled."
    exit 1
fi

# Apply Terraform
echo "🚀 Applying Terraform configuration..."
terraform apply tfplan

# Get kubeconfig
echo "🔑 Getting kubeconfig..."
CLUSTER_ID=$(terraform output -raw cluster_id)
REGION=$(grep -E '^region\s*=' terraform.tfvars | cut -d'"' -f2 || echo "ap-chuncheon-1")
mkdir -p ~/.kube
oci ce cluster create-kubeconfig --cluster-id $CLUSTER_ID --file ~/.kube/config --region $REGION

# Wait for ArgoCD to be ready
echo "⏳ Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd

# Get ArgoCD admin password
echo "🔐 Getting ArgoCD admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)

# Display results
echo ""
echo "✅ Infrastructure deployment completed successfully!"
echo ""
echo "📊 Cluster Information:"
echo "   Cluster ID: $CLUSTER_ID"
echo "   Cluster Name: $(terraform output -raw cluster_name)"
echo "   Region: $REGION"
echo ""
echo "🌐 ArgoCD Information:"
echo "   URL: $(terraform output -raw argocd_server_url)"
echo "   Username: admin"
echo "   Password: $ARGOCD_PASSWORD"
echo ""
echo "📦 Container Registry URLs:"
echo "   Main Registry: $(terraform output -raw container_registry_url)"
echo "   Auth Service: $(terraform output -raw auth_service_registry_url)"
echo "   Nginx Ingress: $(terraform output -raw nginx_ingress_registry_url)"
echo ""
echo "🔐 Secret Management:"
echo "   Vault ID: $(terraform output -raw vault_id)"
echo "   JWT Secret ID: $(terraform output -raw jwt_secret_id)"
echo "   Database Password Secret ID: $(terraform output -raw database_password_secret_id)"
echo ""
echo "💾 Storage Resources:"
echo "   Persistent Volume ID: $(terraform output -raw persistent_volume_id)"
echo "   File System ID: $(terraform output -raw file_system_id)"
echo "   App Data Bucket: $(terraform output -raw app_data_bucket_name)"
echo "   Logs Bucket: $(terraform output -raw logs_bucket_name)"
echo ""
echo "🔧 Useful Commands:"
echo "   Check cluster status: kubectl get nodes"
echo "   Check ArgoCD applications: kubectl get applications -n argocd"
echo "   Port forward ArgoCD: kubectl port-forward svc/argocd-server -n argocd 8080:80"
echo ""
echo "🎉 Deployment completed! Your OCI infrastructure is ready."
