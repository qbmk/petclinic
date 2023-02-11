variable "region" {}
variable "project" {}

resource "google_compute_network" "vpc_network" {
  name                    = "petclinic-vpc"
  auto_create_subnetworks = false
  mtu                     = 1460
}

resource "google_compute_subnetwork" "vpc_subnet" {
  name          = "petclinic-subnet"
  ip_cidr_range = "10.11.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_firewall" "ssh" {
  name = "petclinic-allow-ssh"
  allow {
    ports    = ["22"]
    protocol = "tcp"
  }
  direction     = "INGRESS"
  network       = google_compute_network.vpc_network.id
  priority      = 1000
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}

resource "google_compute_firewall" "web" {
  name = "petclinic-allow-http"
  allow {
    ports    = ["8080", "80"]
    protocol = "tcp"
  }
  direction     = "INGRESS"
  network       = google_compute_network.vpc_network.id
  priority      = 1000
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]
}

resource "google_project_service" "vpcaccess-api" {
  project = var.project
  service = "vpcaccess.googleapis.com"
}

module "serverless-connector" {
  source     = "terraform-google-modules/network/google//modules/vpc-serverless-connector-beta"
  version    = "~> 6.0"
  project_id = var.project
  vpc_connectors = [
       {
        name          = "petclinic-vpc-connector"
         region        = var.region
         network       = google_compute_network.vpc_network.id
         ip_cidr_range = "10.10.11.0/28"
         subnet_name   = null
         machine_type  = "f1-micro"
         min_instances = 2
       max_instances = 7 
       }
  ]
  depends_on = [
    google_project_service.vpcaccess-api
  ]
}