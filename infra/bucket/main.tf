provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

variable "project" {
  default = "epam-project-biba"
}

variable "region" {
  default = "europe-west1"
}

variable "zone" {
  default = "europe-west1-b"
}

resource "google_storage_bucket" "default" {
  name          = "terraform-state-project"
  force_destroy = false
  location      = "EU"
  storage_class = "STANDARD"
  versioning {
    enabled = true
  }
}

resource "google_storage_bucket" "petclinic-artifacts" {
  name          = "petclinic-artifacts"
  force_destroy = false
  location      = "EU"
  storage_class = "STANDARD"
}