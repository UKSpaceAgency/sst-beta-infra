output "fe_route" {
  value = cloudfoundry_route.fe
}

output "api_route" {
  value = cloudfoundry_route.api
}

output "be_batch_route" {
  value = cloudfoundry_route.be_batch
}

output "be_interactive_route" {
  value = cloudfoundry_route.be_interactive
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
