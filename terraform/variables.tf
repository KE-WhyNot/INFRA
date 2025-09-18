variable "tenancy_ocid" {
  description = "OCI Tenancy OCID"
  type        = string
}

variable "user_ocid" {
  description = "OCI User OCID"
  type        = string
}

variable "fingerprint" {
  description = "OCI API Key Fingerprint"
  type        = string
}

variable "private_key_path" {
  description = "Path to OCI API Key Private Key"
  type        = string
}

variable "region" {
  description = "OCI Region"
  type        = string
  default     = "ap-chuncheon-1"
}

variable "config_file_profile" {
  description = "OCI Config File Profile"
  type        = string
  default     = "DEFAULT"
}

variable "compartment_id" {
  description = "OCI Compartment ID"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "infra"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "OKE Cluster name"
  type        = string
  default     = "oke-cluster"
}

variable "cluster_kubernetes_version" {
  description = "Kubernetes version for OKE cluster"
  type        = string
  default     = "v1.33.1"
}

variable "node_pool_name" {
  description = "Node pool name"
  type        = string
  default     = "worker-pool"
}

variable "node_pool_size" {
  description = "Number of nodes in the node pool"
  type        = number
  default     = 3
}

variable "node_shape" {
  description = "Shape of the nodes"
  type        = string
  default     = "VM.Standard.E3.Flex"
}

variable "node_ocpus" {
  description = "Number of OCPUs per node"
  type        = number
  default     = 1
}

variable "node_memory_in_gbs" {
  description = "Memory in GBs per node"
  type        = number
  default     = 16
}

variable "availability_domains" {
  description = "List of availability domains"
  type        = list(string)
  default     = []
}

variable "vcn_cidr" {
  description = "CIDR block for VCN"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidrs" {
  description = "CIDR blocks for subnets"
  type        = map(string)
  default = {
    worker_subnet = "10.0.10.0/24"
    load_balancer_subnet = "10.0.20.0/24"
  }
}

variable "argocd_namespace" {
  description = "Namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "5.51.6"
}

variable "ssh_public_key" {
  description = "SSH public key for node access"
  type        = string
  default     = ""
}
