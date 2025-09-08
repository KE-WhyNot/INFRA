variable "kubeconfig_path" {
  description = "Path to Kubernetes cluster kubeconfig"
  type        = string
  default     = "~/.kube/config"
}