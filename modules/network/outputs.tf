output "fe_route" {
  value = cloudfoundry_route.fe
}

output "api_route" {
  value = cloudfoundry_route.api
}

output "be_route" {
  value = cloudfoundry_route.be
}

output "mp_route" {
  value = cloudfoundry_route.mp
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
