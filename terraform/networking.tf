# Data sources
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

# Cluster kubeconfig will be handled by providers using exec authentication

# VCN
resource "oci_core_vcn" "vcn" {
  compartment_id = var.compartment_id
  display_name   = "${var.project_name}-${var.environment}-vcn"
  cidr_block     = var.vcn_cidr
  dns_label      = "${var.project_name}${var.environment}"

  freeform_tags = {
    "Project"     = var.project_name
    "Environment" = var.environment
    "ManagedBy"   = "Terraform"
  }
}

# Internet Gateway
resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.project_name}-${var.environment}-igw"
  enabled        = true

  freeform_tags = {
    "Project"     = var.project_name
    "Environment" = var.environment
    "ManagedBy"   = "Terraform"
  }
}

# NAT Gateway
resource "oci_core_nat_gateway" "nat_gateway" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.project_name}-${var.environment}-nat-gateway"

  freeform_tags = {
    "Project"     = var.project_name
    "Environment" = var.environment
    "ManagedBy"   = "Terraform"
  }
}

# Service Gateway
resource "oci_core_service_gateway" "service_gateway" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.project_name}-${var.environment}-service-gateway"
  services {
    service_id = data.oci_core_services.all_services.services[0]["id"]
  }

  freeform_tags = {
    "Project"     = var.project_name
    "Environment" = var.environment
    "ManagedBy"   = "Terraform"
  }
}

data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

# Route Table for Private Subnets
resource "oci_core_route_table" "private_route_table" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.project_name}-${var.environment}-private-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.nat_gateway.id
  }

  route_rules {
    destination       = data.oci_core_services.all_services.services[0]["cidr_block"]
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.service_gateway.id
  }

  freeform_tags = {
    "Project"     = var.project_name
    "Environment" = var.environment
    "ManagedBy"   = "Terraform"
  }
}

# Route Table for Public Subnets
resource "oci_core_route_table" "public_route_table" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.project_name}-${var.environment}-public-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw.id
  }

  freeform_tags = {
    "Project"     = var.project_name
    "Environment" = var.environment
    "ManagedBy"   = "Terraform"
  }
}

# Security List for Worker Nodes
resource "oci_core_security_list" "worker_security_list" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.project_name}-${var.environment}-worker-security-list"

  # Egress rules
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  # Ingress rules
  ingress_security_rules {
    protocol = "6"
    source   = var.vcn_cidr
    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = var.vcn_cidr
    tcp_options {
      min = 10250
      max = 10250
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = var.vcn_cidr
    tcp_options {
      min = 30000
      max = 32767
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = var.vcn_cidr
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = var.vcn_cidr
    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = var.vcn_cidr
    tcp_options {
      min = 443
      max = 443
    }
  }

  freeform_tags = {
    "Project"     = var.project_name
    "Environment" = var.environment
    "ManagedBy"   = "Terraform"
  }
}

# Security List for Load Balancer
resource "oci_core_security_list" "lb_security_list" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.project_name}-${var.environment}-lb-security-list"

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

  freeform_tags = {
    "Project"     = var.project_name
    "Environment" = var.environment
    "ManagedBy"   = "Terraform"
  }
}

# Worker Subnet
resource "oci_core_subnet" "worker_subnet" {
  compartment_id      = var.compartment_id
  vcn_id              = oci_core_vcn.vcn.id
  cidr_block          = var.subnet_cidrs.worker_subnet
  display_name        = "${var.project_name}-${var.environment}-worker-subnet"
  dns_label           = "workersubnet"
  route_table_id      = oci_core_route_table.private_route_table.id
  security_list_ids   = [oci_core_security_list.worker_security_list.id]
  prohibit_public_ip_on_vnic = true

  freeform_tags = {
    "Project"     = var.project_name
    "Environment" = var.environment
    "ManagedBy"   = "Terraform"
  }
}

# Load Balancer Subnet
resource "oci_core_subnet" "lb_subnet" {
  compartment_id      = var.compartment_id
  vcn_id              = oci_core_vcn.vcn.id
  cidr_block          = var.subnet_cidrs.load_balancer_subnet
  display_name        = "${var.project_name}-${var.environment}-lb-subnet"
  dns_label           = "lbsubnet"
  route_table_id      = oci_core_route_table.public_route_table.id
  security_list_ids   = [oci_core_security_list.lb_security_list.id]
  prohibit_public_ip_on_vnic = false

  freeform_tags = {
    "Project"     = var.project_name
    "Environment" = var.environment
    "ManagedBy"   = "Terraform"
  }
}
