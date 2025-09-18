# OCI Vault
resource "oci_kms_vault" "vault" {
  compartment_id = var.compartment_id
  display_name   = "${var.project_name}-${var.environment}-vault"
  vault_type     = "DEFAULT"

  freeform_tags = {
    "Project"     = var.project_name
    "Environment" = var.environment
    "ManagedBy"   = "Terraform"
  }
}

# Vault Key for encryption
resource "oci_kms_key" "vault_key" {
  compartment_id      = var.compartment_id
  display_name        = "${var.project_name}-${var.environment}-key"
  management_endpoint = oci_kms_vault.vault.management_endpoint
  key_shape {
    algorithm = "AES"
    length    = 32
  }

  freeform_tags = {
    "Project"     = var.project_name
    "Environment" = var.environment
    "ManagedBy"   = "Terraform"
  }
}

# Secret for JWT
resource "oci_vault_secret" "jwt_secret" {
  compartment_id = var.compartment_id
  vault_id       = oci_kms_vault.vault.id
  key_id         = oci_kms_key.vault_key.id
  secret_name    = "${var.project_name}-${var.environment}-jwt-secret"
  description    = "JWT Secret for authentication service"

  secret_content {
    content_type = "BASE64"
    content      = base64encode("your-jwt-secret-key-change-this-in-production")
  }

  freeform_tags = {
    "Project"     = var.project_name
    "Environment" = var.environment
    "Service"     = "auth-service"
    "ManagedBy"   = "Terraform"
  }
}

# Secret for Database Password
resource "oci_vault_secret" "database_password" {
  compartment_id = var.compartment_id
  vault_id       = oci_kms_vault.vault.id
  key_id         = oci_kms_key.vault_key.id
  secret_name    = "${var.project_name}-${var.environment}-database-password"
  description    = "Database password for authentication service"

  secret_content {
    content_type = "BASE64"
    content      = base64encode("your-database-password-change-this-in-production")
  }

  freeform_tags = {
    "Project"     = var.project_name
    "Environment" = var.environment
    "Service"     = "auth-service"
    "ManagedBy"   = "Terraform"
  }
}

# Secret for ArgoCD Admin Password
resource "oci_vault_secret" "argocd_admin_password" {
  compartment_id = var.compartment_id
  vault_id       = oci_kms_vault.vault.id
  key_id         = oci_kms_key.vault_key.id
  secret_name    = "${var.project_name}-${var.environment}-argocd-admin-password"
  description    = "ArgoCD admin password"

  secret_content {
    content_type = "BASE64"
    content      = base64encode("admin")
  }

  freeform_tags = {
    "Project"     = var.project_name
    "Environment" = var.environment
    "Service"     = "argocd"
    "ManagedBy"   = "Terraform"
  }
}
