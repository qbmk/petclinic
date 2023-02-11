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



data "google_vpc_access_connector" "connectors" {
  name = "petclinic-vpc-connector"
}

data "google_service_account" "petclinic-sa" {
  account_id = "petclinic-sa"
}

resource "google_cloud_run_service" "petclinic" {
  name     = "petclinic"
  provider = google-beta
  location = var.region
  project = var.project

  template {
    spec {
      containers {
        image = "us-docker.pkg.dev/cloudrun/container/hello"
        resources {
          limits = {
            cpu    = "1000m"
            memory = "512M"
          }
        }
      }
      # the service uses this SA to call other Google Cloud APIs
      service_account_name = data.google_service_account.petclinic-sa.email
    }

    metadata {
      annotations = {
        # Limit scale up to prevent any cost blow outs!
        "autoscaling.knative.dev/maxScale" = "5"
        # Use the VPC Connector
        "run.googleapis.com/vpc-access-connector" = data.google_vpc_access_connector.connectors.name
        # all egress from the service should go through the VPC Connector
        "run.googleapis.com/vpc-access-egress" = "all-traffic"
      }
    }
  }
  autogenerate_revision_name = true
}

resource "google_cloud_run_service_iam_member" "run_all_users" {
  service  = google_cloud_run_service.petclinic.name
  location = google_cloud_run_service.petclinic.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

output "service_url" {
  value = google_cloud_run_service.petclinic.status[0].url
}
