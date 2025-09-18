# OKE Cluster
resource "oci_containerengine_cluster" "cluster" {
  compartment_id     = var.compartment_id
  kubernetes_version = var.cluster_kubernetes_version
  name               = "${var.project_name}-${var.environment}-${var.cluster_name}"
  vcn_id             = oci_core_vcn.vcn.id

  endpoint_config {
    is_public_ip_enabled = true
    subnet_id            = oci_core_subnet.lb_subnet.id
  }

  options {
    add_ons {
      is_kubernetes_dashboard_enabled = false
      is_tiller_enabled              = false
    }
    admission_controller_options {
      is_pod_security_policy_enabled = false
    }
    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.96.0.0/16"
    }
    service_lb_subnet_ids = [oci_core_subnet.lb_subnet.id]
  }

  freeform_tags = {
    "Project"     = var.project_name
    "Environment" = var.environment
    "ManagedBy"   = "Terraform"
  }
}

# Node Pool
resource "oci_containerengine_node_pool" "node_pool" {
  cluster_id         = oci_containerengine_cluster.cluster.id
  compartment_id     = var.compartment_id
  kubernetes_version = var.cluster_kubernetes_version
  name               = "${var.project_name}-${var.environment}-${var.node_pool_name}"
  node_shape         = local.node_shape

  node_config_details {
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
      subnet_id          = oci_core_subnet.worker_subnet.id
    }
    size = var.node_pool_size
  }

  ssh_public_key = var.ssh_public_key != "" ? var.ssh_public_key : null

  node_shape_config {
    memory_in_gbs = 16
    ocpus         = 1
  }

  node_source_details {
    image_id    = data.oci_core_images.oke_images.images[0].id
    source_type = "IMAGE"
  }

  initial_node_labels {
    key   = "name"
    value = "${var.project_name}-${var.environment}-node"
  }

  freeform_tags = {
    "Project"     = var.project_name
    "Environment" = var.environment
    "ManagedBy"   = "Terraform"
  }
}

# Get OKE Node Images
data "oci_core_images" "oke_images" {
  compartment_id           = var.compartment_id
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = "VM.Standard.E3.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}
