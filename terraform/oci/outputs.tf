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

