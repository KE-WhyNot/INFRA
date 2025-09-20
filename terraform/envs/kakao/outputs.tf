output "public_subnet_id" { value = openstack_networking_subnet_v2.public.id }
output "private_subnet_id" { value = openstack_networking_subnet_v2.private.id }
output "security_group_id" { value = openstack_networking_secgroup_v2.allow_common.id }
output "k8s_cluster_name" {
  value       = var.create_k8s ? openstack_containerinfra_cluster_v1.cluster[0].name : null
  description = "Magnum cluster name (use openstack coe cluster config to get kubeconfig)"
}

// removed duplicates; outputs are defined once per value


