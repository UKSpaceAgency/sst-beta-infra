output "web_route" {
  value = cloudfoundry_route.web
}

output "spacetrack_route" {
  value = cloudfoundry_route.spacetrack
}

output "esa_discos_route" {
  value = cloudfoundry_route.esa_discos
}

output "api_route" {
  value = cloudfoundry_route.api
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
