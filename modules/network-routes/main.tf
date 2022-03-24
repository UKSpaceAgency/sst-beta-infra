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
  name = "monitor-my-satellites.space"
}

resource "cloudfoundry_route" "web" {
  domain   = "${ var.env_tag == "prod"? data.cloudfoundry_domain.custom.id : data.cloudfoundry_domain.cloudapps.id}"
  hostname = "${ var.env_tag == "prod"? var.custom_subdomain : "${ var.app_web_route_name }-${ var.env_tag }" }"
  space    = var.space.id
}

resource "cloudfoundry_route" "spacetrack" {
  domain   = data.cloudfoundry_domain.internal.id
  hostname = "${ var.app_spacetrack_route_name }-${ var.env_tag }"
  space    = var.space.id
}

resource "cloudfoundry_route" "api" {
  domain   = data.cloudfoundry_domain.cloudapps.id
  hostname = "${ var.app_api_route_name }-${ var.env_tag }"
  space    = var.space.id
}

resource "cloudfoundry_route" "maintenance" {
  domain   = data.cloudfoundry_domain.internal.id
  hostname = "${ var.app_maintenance_route_name }-${ var.env_tag }"
  space    = var.space.id
}
