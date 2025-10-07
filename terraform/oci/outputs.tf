output "cluster_id" {
  description = "OKE cluster ID"
  value       = oci_containerengine_cluster.oke_cluster.id
}

output "cluster_name" {
  description = "OKE cluster name"
  value       = oci_containerengine_cluster.oke_cluster.name
}

output "cluster_endpoint" {
  description = "OKE cluster endpoint"
  value       = oci_containerengine_cluster.oke_cluster.endpoints[0].kubernetes
}

output "vcn_id" {
  description = "VCN ID"
  value       = oci_core_vcn.oke_vcn.id
}

output "worker_subnet_id" {
  description = "Worker subnet ID"
  value       = oci_core_subnet.oke_worker_subnet.id
}

output "lb_subnet_id" {
  description = "Load balancer subnet ID"
  value       = oci_core_subnet.oke_lb_subnet.id
}

output "node_pool_id" {
  description = "Node pool ID"
  value       = oci_containerengine_node_pool.oke_node_pool.id
}

output "kubeconfig_command" {
  description = "Command to generate kubeconfig"
  value       = "oci ce cluster create-kubeconfig --cluster-id ${oci_containerengine_cluster.oke_cluster.id} --file ~/.kube/config --region ${var.region}"
}

# ArgoCD Outputs
output "argocd_namespace" {
  description = "ArgoCD namespace"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "argocd_server_url" {
  description = "ArgoCD server URL"
  value       = "https://${var.argocd_server_host}"
}

output "argocd_access_command" {
  description = "Command to access ArgoCD"
  value       = "Open browser and go to: https://${var.argocd_server_host}"
}

output "argocd_port_forward_command" {
  description = "Command to port forward ArgoCD"
  value       = "kubectl port-forward svc/argocd-server -n argocd 8080:443"
}

output "argocd_admin_username" {
  description = "ArgoCD admin username"
  value       = "admin"
}

output "argocd_admin_password" {
  description = "ArgoCD admin password"
  value       = var.argocd_admin_password
  sensitive   = true
}

# Nginx Ingress Outputs
output "nginx_ingress_namespace" {
  description = "Nginx Ingress namespace"
  value       = kubernetes_namespace.nginx_ingress.metadata[0].name
}

output "nginx_ingress_class" {
  description = "Nginx Ingress class name"
  value       = var.nginx_ingress_class
}

output "reserved_public_ip" {
  description = "Reserved Public IP address for Load Balancer"
  value       = local.reserved_ip_address
}

output "dns_setup_command" {
  description = "DNS setup command for youth-fi.com domain"
  value       = "Add A record: argocd.youth-fi.com -> ${local.reserved_ip_address}"
}

output "letsencrypt_issuer_status" {
  description = "Let's Encrypt ClusterIssuer status"
  value       = "ClusterIssuers created automatically via Terraform"
}

