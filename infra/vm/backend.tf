terraform {
 backend "gcs" {
   bucket  = "terraform-state-project"
   prefix  = "terraform/state_vm"
 }
}