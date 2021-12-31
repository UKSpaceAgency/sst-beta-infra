resource "cloudfoundry_route" "app_route_cloud" {
  domain   = data.cloudfoundry_domain.cloudapps.id
  hostname = var.paas_app_route_name
  space    = data.cloudfoundry_space.space.id
}

resource "cloudfoundry_route" "api_route_internal" {
  domain   = data.cloudfoundry_domain.internal.id
  hostname = var.paas_app_api_route_name
  space    = data.cloudfoundry_space.space.id
}

resource "cloudfoundry_route" "app_be_internal" {
  domain   = data.cloudfoundry_domain.internal.id
  hostname = var.paas_app_be_route_name
  space    = data.cloudfoundry_space.space.id
}

resource "cloudfoundry_route" "app_route_custom_domain" {
  count    = var.paas_custom_domain_flag ? 1 : 0
  domain   = data.cloudfoundry_domain.custom.id
  hostname = var.paas_custom_subdomain
  space    = data.cloudfoundry_space.space.id
}
