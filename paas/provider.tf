terraform {
  required_providers {
    cloudfoundry = {
      source  = "cloudfoundry-community/cloudfoundry"
      version = "0.14.2"
    }
  }
}

provider "cloudfoundry" {
  api_url  = var.api_url
  user     = var.paas_username
  password = var.paas_password
}

