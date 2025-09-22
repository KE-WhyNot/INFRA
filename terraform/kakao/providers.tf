# Terraform 설정
terraform {
  required_version = ">= 1.0"

  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = ">= 1.40.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.29.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.13.0"
    }
  }
}

# OpenStack Provider 설정 (카카오클라우드용)
provider "openstack" {
  auth_url                      = var.kc_auth_url
  application_credential_id     = var.kc_application_credential_id
  application_credential_secret = var.kc_application_credential_secret
  region                        = var.kc_region
}

# Kubernetes/Helm providers (will use kubeconfig fetched from master)
provider "kubernetes" {
  config_path = "${path.module}/kubeconfig/admin.conf"
}

provider "helm" {
  kubernetes = {
    config_path = "${path.module}/kubeconfig/admin.conf"
  }
}
