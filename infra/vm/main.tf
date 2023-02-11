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

data "google_compute_address" "jenkins-ip" {
  name = "jenkins-ip"
}

data "google_compute_network" "petclinic-vpc" {
  name = "petclinic-vpc"
}

module "vm" {
	source = "./modules/jenkins"
	region = var.region
  project = var.project
  zone    = var.zone
}

resource "google_compute_global_address" "private_ip_block" {
  name         = "private-ip-block"
  purpose      = "VPC_PEERING"
  address_type = "INTERNAL"
  ip_version   = "IPV4"
  prefix_length = 24
  network       = data.google_compute_network.petclinic-vpc.self_link
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = data.google_compute_network.petclinic-vpc.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_block.name]
}

resource "google_sql_database_instance" "instance" {
  name             = "petclinic"
  region           = var.region
  database_version = "MYSQL_5_7"
  depends_on       = [google_service_networking_connection.private_vpc_connection]
  deletion_protection = false

  settings {
    tier = "db-f1-micro"
    availability_type = "ZONAL"

    ip_configuration {
        ipv4_enabled    = false
        private_network = data.google_compute_network.petclinic-vpc.self_link

        authorized_networks {
          name = "default"
          value = "0.0.0.0/0"
        }
      }
  }
}

resource "google_sql_database" "petclinic" {
  name     = "petclinic"
  instance = google_sql_database_instance.instance.name
}

resource "google_sql_database" "petclinic_biba" {
  name     = "petclinic_biba"
  instance = google_sql_database_instance.instance.name
}

resource "google_sql_user" "users" {
  name     = "petclinic"
  password = "petclinic"
  instance = google_sql_database_instance.instance.name
}

output "db_instance_ip_addr" {
  value       = google_sql_database_instance.instance.private_ip_address
  description = "The private IP address of the db server."
}

output "connection_name" {
  value       = google_sql_database_instance.instance.connection_name
  description = "Cloud SQL connection name."
}

output "jenkins_ip" {
  value       = data.google_compute_address.jenkins-ip.address
  description = "Jenkins IP address"
}
