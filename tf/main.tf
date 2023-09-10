variable "project_id" {
  description = "project id"
}

variable "region" {
  description = "region"
}

variable "zone" {
  description = "zone"
}

variable "gke_num_nodes" {
  default     = 1
  description = "number of gke nodes per zone"
}

data "google_container_engine_versions" "gke_version" {
  location       = var.region
  version_prefix = "1.27."
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_artifact_registry_repository" "gke-repository" {
  location      = "us-central1"
  repository_id = "gke-repository"
  description   = "Docker repository for GKE container images"
  format        = "DOCKER"
}

resource "google_service_account" "gke_cluster_service_account" {
  account_id   = "gke-cluster-service-account"
  display_name = "GKE Cluster Service Account"
}

resource "google_container_cluster" "primary" {
  name     = "${var.project_id}-test-gke"
  location = var.region

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.gke_vpc.name
  subnetwork = google_compute_subnetwork.gke_subnet.name
}

resource "google_container_node_pool" "primary_nodes" {
  name     = google_container_cluster.primary.name
  location = var.region
  cluster  = google_container_cluster.primary.name

  version    = data.google_container_engine_versions.gke_version.release_channel_latest_version["STABLE"]
  node_count = var.gke_num_nodes

  node_config {
    machine_type = "n1-standard-1"

    service_account = google_service_account.gke_cluster_service_account.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      env = var.project_id
    }

    tags = ["gke-node", "${var.project_id}-test-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

resource "google_compute_network" "gke_vpc" {
  name                    = "${var.project_id}-gene-test-vpc"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "gke_subnet" {
  name          = "${google_compute_network.gke_vpc.name}-subnet"
  region        = var.region
  network       = google_compute_network.gke_vpc.name
  ip_cidr_range = "10.10.0.0/24"
}
