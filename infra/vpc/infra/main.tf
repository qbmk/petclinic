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

module "vpc" {
	source = "./modules/vpc"
	region = var.region
  project = var.project
}

module "ip" {
	source = "./modules/ip"
}
