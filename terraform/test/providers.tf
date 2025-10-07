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
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.13.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.23.0"
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


provider "helm" {
  kubernetes = {
    config_path = "/Users/parkyoungdu/.kube/config"
  }
}

provider "kubernetes" {
  config_path = "/Users/parkyoungdu/.kube/config"
}

# OpenStack Kubernetes 클러스터용 kubectl provider 설정
provider "kubectl" {
  config_path = "/Users/parkyoungdu/.kube/config"
  insecure    = true  # TLS 인증서 검증 비활성화
}