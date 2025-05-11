# Tell terraform to use the provider and select a version.
terraform {
 backend "remote" {
   hostname = "app.terraform.io"
   organization = "andre-org"
   workspaces {
     name = "infra"
   }
 }

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
}

# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = var.hcloud_token
}
