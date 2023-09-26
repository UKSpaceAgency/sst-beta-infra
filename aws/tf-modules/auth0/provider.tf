terraform {
  required_version = ">= 1.4.5"
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "~> 0.48.0"
    }
  }
}
provider "auth0" {
  domain = var.auth0_domain
  client_id = var.auth_client_id
  client_secret = var.auth_client_secret
}