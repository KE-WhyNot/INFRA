terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 7.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

# OCI provider
provider "oci" {
  region           = var.region
  tenancy_ocid     = var.tenancy_id
  user_ocid        = var.user_id
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
}

# Kubernetes provider 
provider "kubernetes" {
  config_path = pathexpand("~/.kube/oke.yaml")
}

# Helm provider
provider "helm" {
  kubernetes {
    config_path = pathexpand("~/.kube/oke.yaml")
  }
}
