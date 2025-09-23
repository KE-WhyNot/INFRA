# Get availability domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

# VCN
resource "oci_core_vcn" "oke_vcn" {
  compartment_id = var.compartment_id
  display_name   = "${var.environment}-oke-vcn"
  cidr_blocks    = [var.vcn_cidr]
  dns_label      = "okevcn"
}

# Internet Gateway
resource "oci_core_internet_gateway" "oke_ig" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.oke_vcn.id
  display_name   = "${var.environment}-oke-ig"
}

# Route Table
resource "oci_core_route_table" "oke_rt" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.oke_vcn.id
  display_name   = "${var.environment}-oke-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.oke_ig.id
  }
}

# Security List for worker nodes
resource "oci_core_security_list" "oke_worker_seclist" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.oke_vcn.id
  display_name   = "${var.environment}-oke-worker-seclist"

  # Egress rules
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  # Ingress rules
  ingress_security_rules {
    protocol = "all"
    source   = var.vcn_cidr
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 10250
      max = 10250
    }
  }
}

# Security List for load balancer
resource "oci_core_security_list" "oke_lb_seclist" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.oke_vcn.id
  display_name   = "${var.environment}-oke-lb-seclist"

  # Egress rules
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  # Ingress rules
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 443
      max = 443
    }
  }
}

# Subnet for worker nodes
resource "oci_core_subnet" "oke_worker_subnet" {
  compartment_id      = var.compartment_id
  vcn_id              = oci_core_vcn.oke_vcn.id
  display_name        = "${var.environment}-oke-worker-subnet"
  cidr_block          = var.subnet_cidr
  dns_label           = "workersubnet"
  route_table_id      = oci_core_route_table.oke_rt.id
  security_list_ids   = [oci_core_security_list.oke_worker_seclist.id]
  prohibit_public_ip_on_vnic = false
}

# Subnet for load balancer
resource "oci_core_subnet" "oke_lb_subnet" {
  compartment_id      = var.compartment_id
  vcn_id              = oci_core_vcn.oke_vcn.id
  display_name        = "${var.environment}-oke-lb-subnet"
  cidr_block          = var.load_balancer_subnet_cidr
  dns_label           = "lbsubnet"
  route_table_id      = oci_core_route_table.oke_rt.id
  security_list_ids   = [oci_core_security_list.oke_lb_seclist.id]
  prohibit_public_ip_on_vnic = false
}

# OKE Cluster
resource "oci_containerengine_cluster" "oke_cluster" {
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  name               = var.cluster_name
  vcn_id             = oci_core_vcn.oke_vcn.id

  endpoint_config {
    is_public_ip_enabled = true
    subnet_id            = oci_core_subnet.oke_worker_subnet.id
  }

  options {
    add_ons {
      is_kubernetes_dashboard_enabled = true
      is_tiller_enabled              = false
    }
    admission_controller_options {
      is_pod_security_policy_enabled = false
    }
    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.96.0.0/16"
    }
    service_lb_subnet_ids = [oci_core_subnet.oke_lb_subnet.id]
  }
}

# Node Pool
resource "oci_containerengine_node_pool" "oke_node_pool" {
  cluster_id         = oci_containerengine_cluster.oke_cluster.id
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  name               = var.node_pool_name
  node_config_details {
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
      subnet_id           = oci_core_subnet.oke_worker_subnet.id
    }
    size = var.node_count
  }
  node_shape = var.node_shape
  node_shape_config {
    memory_in_gbs = var.node_memory_in_gbs
    ocpus         = var.node_ocpus
  }
  node_source_details {
    image_id    = data.oci_core_images.oke_node_pool_images.images[0].id
    source_type = "IMAGE"
  }
  initial_node_labels {
    key   = "name"
    value = var.node_pool_name
  }
}

# Get OKE node pool images
data "oci_core_images" "oke_node_pool_images" {
  compartment_id           = var.compartment_id
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = var.node_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

