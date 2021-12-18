resource "cloudfoundry_user_provided_service" "logit" {
  name             = var.logit_service_name
  space            = data.cloudfoundry_space.space.id
  syslog_drain_url = var.logit_endpoint
}