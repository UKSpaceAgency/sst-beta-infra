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

resource "cloudfoundry_route" "be" {
  domain   = data.cloudfoundry_domain.internal.id
  hostname = "${ var.app_be_route_name }-${ var.env_tag }"
  space    = var.space.id
}

resource "cloudfoundry_route" "mp" {
  domain   = data.cloudfoundry_domain.internal.id
  hostname = "${ var.app_mp_route_name }-${ var.env_tag }"
  space    = var.space.id
}
/*
resource "cloudfoundry_route" "app_route_custom_domain" {
  count    = var.custom_domain_flag ? 1 : 0
  domain   = data.cloudfoundry_domain.custom.id
  hostname = var.custom_subdomain
  space    = var.space.id
}
*/
