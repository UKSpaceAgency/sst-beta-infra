output "web_route" {
  value = cloudfoundry_route.web
}

output "web-gov_route" {
  value = cloudfoundry_route.web-gov
}

output "spacetrack_route" {
  value = cloudfoundry_route.spacetrack
}

output "api_route" {
  value = cloudfoundry_route.api
}

output "api-gov_route" {
  value = cloudfoundry_route.api-gov
}

output "maintenance_route" {
  value = cloudfoundry_route.maintenance
}

output "internal_domain" {
  value = data.cloudfoundry_domain.internal
}

output "cloudapps_domain" {
  value = data.cloudfoundry_domain.cloudapps
}

output "custom_domain" {
  value = data.cloudfoundry_domain.custom
}
