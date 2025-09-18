# OCI Block Volume for persistent storage
resource "oci_core_volume" "persistent_volume" {
  compartment_id      = var.compartment_id
  display_name        = "${var.project_name}-${var.environment}-persistent-volume"
  size_in_gbs         = 100
  vpus_per_gb         = 10
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name

  freeform_tags = {
    "Project"     = var.project_name
    "Environment" = var.environment
    "ManagedBy"   = "Terraform"
  }
}

# OCI File System for shared storage
resource "oci_file_storage_file_system" "file_system" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_id
  display_name        = "${var.project_name}-${var.environment}-file-system"

  freeform_tags = {
    "Project"     = var.project_name
    "Environment" = var.environment
    "ManagedBy"   = "Terraform"
  }
}

# File System Mount Target
resource "oci_file_storage_mount_target" "mount_target" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_id
  subnet_id           = oci_core_subnet.worker_subnet.id
  display_name        = "${var.project_name}-${var.environment}-mount-target"

  freeform_tags = {
    "Project"     = var.project_name
    "Environment" = var.environment
    "ManagedBy"   = "Terraform"
  }
}

# File System Export
resource "oci_file_storage_export" "export" {
  export_set_id  = oci_file_storage_mount_target.mount_target.export_set_id
  file_system_id = oci_file_storage_file_system.file_system.id
  path           = "/shared"
}

# Object Storage Bucket for application data
resource "oci_objectstorage_bucket" "app_data_bucket" {
  compartment_id = var.compartment_id
  name           = "${var.project_name}-${var.environment}-app-data"
  namespace      = data.oci_objectstorage_namespace.ns.namespace

  freeform_tags = {
    "Project"     = var.project_name
    "Environment" = var.environment
    "ManagedBy"   = "Terraform"
  }
}

# Object Storage Bucket for logs
resource "oci_objectstorage_bucket" "logs_bucket" {
  compartment_id = var.compartment_id
  name           = "${var.project_name}-${var.environment}-logs"
  namespace      = data.oci_objectstorage_namespace.ns.namespace

  freeform_tags = {
    "Project"     = var.project_name
    "Environment" = var.environment
    "ManagedBy"   = "Terraform"
  }
}

# Get Object Storage Namespace
data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.compartment_id
}
