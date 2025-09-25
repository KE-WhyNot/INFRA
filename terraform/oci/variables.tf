variable "region" {
  description = "OCI region"
  type        = string
  default     = "ap-chuncheon-1"
}

variable "tenancy_id" {
  description = "OCI tenancy ID"
  type        = string
}

variable "user_id" {
  description = "OCI user ID"
  type        = string
}

variable "fingerprint" {
  description = "OCI API key fingerprint"
  type        = string
}

variable "private_key_path" {
  description = "Path to OCI private key file"
  type        = string
  default     = "~/.oci/oci_api_key.pem"
}

variable "compartment_id" {
  description = "OCI compartment ID"
  type        = string
}

variable "cluster_name" {
  description = "OKE cluster name"
  type        = string
  default     = "dev-oke-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "v1.31.1"
}

variable "node_pool_name" {
  description = "Node pool name"
  type        = string
  default     = "dev-node-pool"
}

variable "node_shape" {
  description = "Node shape"
  type        = string
  default     = "VM.Standard.E4.Flex"
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

variable "node_count" {
  description = "Number of nodes in the node pool"
  type        = number
  default     = 3
}

variable "availability_domains" {
  description = "Availability domains"
  type        = list(string)
  default     = []
}

variable "vcn_cidr" {
  description = "VCN CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "Subnet CIDR block"
  type        = string
  default     = "10.0.1.0/24"
}

variable "load_balancer_subnet_cidr" {
  description = "Load balancer subnet CIDR block"
  type        = string
  default     = "10.0.2.0/24"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# ArgoCD Variables
variable "argocd_namespace" {
  description = "ArgoCD namespace"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "5.51.6"
}

variable "argocd_server_host" {
  description = "ArgoCD server host"
  type        = string
  default     = "argocd.example.com"
}

variable "argocd_admin_password" {
  description = "ArgoCD admin password"
  type        = string
  sensitive   = true
}

# Nginx Ingress Variables
variable "nginx_ingress_namespace" {
  description = "Nginx Ingress namespace"
  type        = string
  default     = "ingress-nginx"
}

variable "nginx_ingress_chart_version" {
  description = "Nginx Ingress Helm chart version"
  type        = string
  default     = "4.8.3"
}

variable "nginx_ingress_class" {
  description = "Nginx Ingress class name"
  type        = string
  default     = "nginx"
}

# Cert-Manager 설정
variable "cert_manager_chart_version" {
  description = "Cert-Manager Helm chart version"
  type        = string
  default     = "v1.13.3"
}

variable "letsencrypt_email" {
  description = "Email for Let's Encrypt certificate registration"
  type        = string
  default     = "admin@youth-fi.com"
}

# 기존 고정 IP 설정
variable "existing_reserved_ip_id" {
  description = "OCID of existing reserved public IP"
  type        = string
}
 