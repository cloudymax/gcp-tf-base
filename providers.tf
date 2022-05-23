terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.21.0"
    }
  }
}

# https://registry.terraform.io/providers/hashicorp/google/4.21.0
provider "google" {
  project     = var.project_id
  region      = var.location
  zone        = var.main_availability_zone
  credentials = file(var.credentials_path)
}
