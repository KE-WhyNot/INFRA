terraform {
  required_version = ">= 1.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = ">= 1.40.0"
    }
  }
}

variable "kc_region" {}
variable "kc_availability_zone" {}
variable "kc_auth_url" {}
variable "kc_access_key" {}
variable "kc_secret_key" {}
provider "openstack" {
  auth_url                    = var.kc_auth_url
  application_credential_id   = var.kc_access_key
  application_credential_secret = var.kc_secret_key
  region                      = var.kc_region
}

