# OCI Container Registry
resource "oci_artifacts_container_repository" "container_repository" {
  compartment_id = var.compartment_id
  display_name    = "${var.project_name}-${var.environment}-registry"
  is_immutable    = false
  is_public       = false

  freeform_tags = {
    "Project"     = var.project_name
    "Environment" = var.environment
    "ManagedBy"   = "Terraform"
  }
}

# Container Registry Repository for Auth Service
resource "oci_artifacts_container_repository" "auth_service_repository" {
  compartment_id = var.compartment_id
  display_name    = "${var.project_name}-${var.environment}-auth-service"
  is_immutable    = false
  is_public       = false

  freeform_tags = {
    "Project"     = var.project_name
    "Environment" = var.environment
    "Service"     = "auth-service"
    "ManagedBy"   = "Terraform"
  }
}

# Container Registry Repository for Nginx Ingress
resource "oci_artifacts_container_repository" "nginx_ingress_repository" {
  compartment_id = var.compartment_id
  display_name    = "${var.project_name}-${var.environment}-nginx-ingress"
  is_immutable    = false
  is_public       = false

  freeform_tags = {
    "Project"     = var.project_name
    "Environment" = var.environment
    "Service"     = "nginx-ingress"
    "ManagedBy"   = "Terraform"
  }
}
