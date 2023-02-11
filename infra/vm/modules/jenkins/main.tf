variable "project" {}

variable "region" {}

variable "zone" {}

data "google_compute_address" "jenkins-ip" {
  name = "petclinic-public-ip-tf"
}

data "google_compute_image" "jenkins" {
  family  = "petclinic"
  project = var.project
}

data "google_service_account" "jenkins-sa" {
  account_id = "jenkins-sa"
}

resource "google_compute_instance" "jenkins" {
  name         = "jenkins"
  machine_type = "e2-medium" 
  zone         = var.zone
  tags = ["web", "ssh"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.jenkins.self_link
    }
  }
  
  network_interface {
    network = "petclinic-vpc"
    subnetwork ="petclinic-subnet"
    access_config {
      nat_ip = data.google_compute_address.jenkins-ip.address
    }
  }

  service_account {
    email  = data.google_service_account.jenkins-sa.email
    scopes = ["cloud-platform"]
  }
}