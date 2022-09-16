terraform {
  required_providers {
    cloudfoundry = {
      source  = "cloudfoundry-community/cloudfoundry"
      version = ">=0.15.0"
    }
  }
}

data "cloudfoundry_domain" "cloudapps" {
  name = "london.cloudapps.digital"
}

data "cloudfoundry_domain" "internal" {
  name = "apps.internal"
}

data "cloudfoundry_domain" "custom" {
  name     = "monitor-your-satellites.service.gov.uk"
}

resource "cloudfoundry_route" "web" {
  domain   = data.cloudfoundry_domain.custom.id
  hostname = "${var.env_tag == "prod" ? var.custom_web_subdomain : "${var.env_tag}"}"
  space    = var.space.id
  target   = { app = var.web_target.id }
}

resource "cloudfoundry_route" "spacetrack" {
  domain   = data.cloudfoundry_domain.internal.id
  hostname = "${var.app_spacetrack_route_name}-${var.env_tag}"
  space    = var.space.id
}

resource "cloudfoundry_route" "esa_discos" {
  domain   = data.cloudfoundry_domain.internal.id
  hostname = "${var.app_esa_discos_route_name}-${var.env_tag}"
  space    = var.space.id
}

resource "cloudfoundry_route" "api" {

  domain   = data.cloudfoundry_domain.custom.id
  hostname = "${var.env_tag == "prod" ? var.custom_api_subdomain : "${var.custom_api_subdomain}-${var.env_tag}"}"
  space    = var.space.id
}

resource "cloudfoundry_route" "maintenance" {
  domain   = data.cloudfoundry_domain.internal.id
  hostname = "${var.app_maintenance_route_name}-${var.env_tag}"
  space    = var.space.id
  target   = { app = var.maintenance_target.id }
}
