terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
    # Uncomment below if you want Terraform to manage Kubernetes resources
    # helm = {
    #   source  = "hashicorp/helm"
    #   version = "~> 2.0"
    # }
    # kubernetes = {
    #   source  = "hashicorp/kubernetes"
    #   version = "~> 2.0"
    # }
  }
}

provider "oci" {
  tenancy_ocid         = var.tenancy_ocid
  user_ocid            = var.user_ocid
  fingerprint          = var.fingerprint
  private_key_path     = var.private_key_path
  region               = var.region
}

# Note: Kubernetes and Helm providers are commented out since ArgoCD is managed separately
# Uncomment below if you want Terraform to manage Kubernetes resources

# Get cluster kubeconfig
# data "oci_containerengine_cluster_kube_config" "cluster_kube_config" {
#   cluster_id = oci_containerengine_cluster.cluster.id
# }

# provider "kubernetes" {
#   config_path = "~/.kube/config"
# }

# provider "helm" {
#   kubernetes {
#     config_path = "~/.kube/config"
#   }
# }