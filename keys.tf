# Create a keyring
resource "google_kms_key_ring" "keyring" {
  name     = var.keyring
  location = var.location
  project  = var.project_id
}

# add a key to the keyring
resource "google_kms_crypto_key" "key" {
  name            = var.keyring_key
  key_ring        = google_kms_key_ring.keyring.id
  rotation_period = "100000s"

  lifecycle {
    prevent_destroy = true
  }
}

# Give our service accout we created in iam.tf access to the keyring
data "google_iam_policy" "keyEditor" {
  binding {
    role = "roles/editor"

    members = [
      "group:${google_cloud_identity_group.cloud_identity_group_basic.id}",
    ]
  }
}

# Create a service account key
resource "google_service_account_key" "mykey" {
  service_account_id = google_service_account.service_account.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

# add policy for keyring from we crated in iam.tf 
resource "google_kms_key_ring_iam_policy" "key_ring_policy" {
  key_ring_id = google_kms_key_ring.keyring.id
  policy_data = data.google_iam_policy.keyEditor.policy_data
}
