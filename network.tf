# A host project provides network resources to associated service projects.
resource "google_compute_shared_vpc_host_project" "host" {
  project = var.project_id
}

resource "google_compute_network" "network" {
  name                    = "${var.project_id}-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "default" {
  name          = "${var.project_id}-subnet"
  ip_cidr_range = "10.0.0.0/16"
  region        = var.location
  network       = google_compute_network.network.id
}

resource "google_compute_address" "internal_with_subnet_and_address" {
  name         = "my-internal-address"
  subnetwork   = google_compute_subnetwork.default.id
  address_type = "INTERNAL"
  address      = "10.0.42.42"
  region       = "us-central1"
}