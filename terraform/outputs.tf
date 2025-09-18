# Outputs
output "cluster_id" {
  description = "OKE Cluster ID"
  value       = oci_containerengine_cluster.cluster.id
}

output "cluster_name" {
  description = "OKE Cluster Name"
  value       = oci_containerengine_cluster.cluster.name
}

output "cluster_endpoint" {
  description = "OKE Cluster Endpoint"
  value       = oci_containerengine_cluster.cluster.endpoints[0].kubernetes
  sensitive   = true
}

output "node_pool_id" {
  description = "Node Pool ID"
  value       = oci_containerengine_node_pool.node_pool.id
}

output "vcn_id" {
  description = "VCN ID"
  value       = oci_core_vcn.vcn.id
}

output "worker_subnet_id" {
  description = "Worker Subnet ID"
  value       = oci_core_subnet.worker_subnet.id
}

output "lb_subnet_id" {
  description = "Load Balancer Subnet ID"
  value       = oci_core_subnet.lb_subnet.id
}

output "container_registry_id" {
  description = "Container Registry ID"
  value       = oci_artifacts_container_repository.container_repository.id
}

output "container_registry_url" {
  description = "Container Registry URL"
  value       = "${data.oci_objectstorage_namespace.ns.namespace}.ocir.${var.region}.oci.oraclecloud.com"
}

output "auth_service_registry_url" {
  description = "Auth Service Container Registry URL"
  value       = "${data.oci_objectstorage_namespace.ns.namespace}.ocir.${var.region}.oci.oraclecloud.com/${oci_artifacts_container_repository.auth_service_repository.display_name}"
}

output "nginx_ingress_registry_url" {
  description = "Nginx Ingress Container Registry URL"
  value       = "${data.oci_objectstorage_namespace.ns.namespace}.ocir.${var.region}.oci.oraclecloud.com/${oci_artifacts_container_repository.nginx_ingress_repository.display_name}"
}

output "vault_id" {
  description = "Vault ID"
  value       = oci_kms_vault.vault.id
}

output "vault_key_id" {
  description = "Vault Key ID"
  value       = oci_kms_key.vault_key.id
}

output "jwt_secret_id" {
  description = "JWT Secret ID"
  value       = oci_vault_secret.jwt_secret.id
}

output "database_password_secret_id" {
  description = "Database Password Secret ID"
  value       = oci_vault_secret.database_password.id
}

output "argocd_admin_password_secret_id" {
  description = "ArgoCD Admin Password Secret ID"
  value       = oci_vault_secret.argocd_admin_password.id
}

output "persistent_volume_id" {
  description = "Persistent Volume ID"
  value       = oci_core_volume.persistent_volume.id
}

output "file_system_id" {
  description = "File System ID"
  value       = oci_file_storage_file_system.file_system.id
}

output "file_system_export_path" {
  description = "File System Export Path"
  value       = oci_file_storage_export.export.path
}

output "file_system_mount_target_id" {
  description = "File System Mount Target ID"
  value       = oci_file_storage_mount_target.mount_target.id
}

output "app_data_bucket_name" {
  description = "Application Data Bucket Name"
  value       = oci_objectstorage_bucket.app_data_bucket.name
}

output "logs_bucket_name" {
  description = "Logs Bucket Name"
  value       = oci_objectstorage_bucket.logs_bucket.name
}

output "argocd_namespace" {
  description = "ArgoCD Namespace (managed separately)"
  value       = var.argocd_namespace
}

output "argocd_server_url" {
  description = "ArgoCD Server URL (if installed)"
  value       = "https://argocd.${var.project_name}-${var.environment}.local"
}

output "kubeconfig_command" {
  description = "Command to get kubeconfig"
  value       = "oci ce cluster create-kubeconfig --cluster-id ${oci_containerengine_cluster.cluster.id} --file ~/.kube/config --region ${var.region}"
}

output "argocd_admin_password_command" {
  description = "Command to get ArgoCD admin password (if installed)"
  value       = "kubectl -n ${var.argocd_namespace} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}

output "argocd_install_command" {
  description = "Command to install ArgoCD manually"
  value       = "cd /Users/dayoung/Documents/INFRA && ./deploy-argocd.sh"
}
