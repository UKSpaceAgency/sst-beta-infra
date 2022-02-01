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

resource "cloudfoundry_route" "fe" {
  domain   = "${ var.env_tag == "prod"? data.cloudfoundry_domain.custom.id : data.cloudfoundry_domain.cloudapps.id}"
  hostname = "${ var.env_tag == "prod"? var.custom_subdomain : "${ var.app_fe_route_name }-${ var.env_tag }" }"
  space    = var.space.id
}

resource "cloudfoundry_route" "api" {
  domain   = data.cloudfoundry_domain.internal.id
  hostname = "${ var.app_api_route_name }-${ var.env_tag }"
  space    = var.space.id
}

resource "cloudfoundry_route" "be_batch" {
  domain   = data.cloudfoundry_domain.internal.id
  hostname = "${ var.app_be_batch_route_name }-${ var.env_tag }"
  space    = var.space.id
}

resource "cloudfoundry_route" "be_interactive" {
  domain   = data.cloudfoundry_domain.internal.id
  hostname = "${ var.app_be_interactive_route_name }-${ var.env_tag }"
  space    = var.space.id
}

resource "cloudfoundry_route" "mp" {
  domain   = data.cloudfoundry_domain.internal.id
  hostname = "${ var.app_mp_route_name }-${ var.env_tag }"
  space    = var.space.id
}
