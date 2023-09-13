terraform {

  backend "gcs" {
    bucket = "gke-tpu-cluster-tf-state"
    prefix = "terraform/state"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.74.0"
    }
  }

  required_version = ">= 0.14"
}
