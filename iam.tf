# Create a group
resource "google_cloud_identity_group" "cloud_identity_group_basic" {
  display_name         = var.big_robot_group
  initial_group_config = "WITH_INITIAL_OWNER"

  parent = "identitysources/${var.organization}"

  group_key {
    id = "${var.big_robot_group}@${var.organization}"
  }

  labels = {
    "system/groups/external" = var.big_robot_group
  }
}

# Add roles to the group - could probaly be put into a loop
data "google_iam_policy" "owner" {

  binding {
    role = "roles/owner"

    members = [
      "group:${google_cloud_identity_group.cloud_identity_group_basic.id}",
    ]
  }
}

data "google_iam_policy" "saUser" {

  binding {
    role = "roles/iam.serviceAccountUser"

    members = [
      "group:${google_cloud_identity_group.cloud_identity_group_basic.id}",
    ]
  }
}

# create a service account
resource "google_service_account" "service_account" {
  account_id   = var.big_robot_name
  display_name = "Service Account for ${data.google_client_config.current.id}"
}

# add service account to group
resource "google_cloud_identity_group_membership" "cloud_identity_group_membership_basic" {
  group = google_cloud_identity_group.cloud_identity_group_basic.id

  preferred_member_key {
    id = google_cloud_identity_group.cloud_identity_group_basic.group_key[0].id
  }

  roles {
    name = "MEMBER"
  }
}