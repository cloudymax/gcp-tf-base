resource "google_storage_bucket" "bucket" {
  name          = var.backend_bucket_name
  location      = var.location
  project       = var.project_id
  force_destroy = true

  versioning {
    enabled = true
  }

  uniform_bucket_level_access = true
}