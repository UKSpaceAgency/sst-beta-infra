terraform {
  required_providers {
    cloudfoundry = {
      source  = "cloudfoundry-community/cloudfoundry"
      version = ">=0.15.0"
    }
  }
}

resource "cloudfoundry_network_policy" "fe_api_policy" {
  policy {
    source_app      = var.app_app.id
    destination_app = var.api_app.id
    port = "8080"
    protocol = "tcp"
  }
}

resource "cloudfoundry_network_policy" "api_be_policy" {
  policy {
    source_app      = var.api_app.id
    destination_app = var.be_app.id
    port            = "8080"
    protocol        = "tcp"
  }
}
