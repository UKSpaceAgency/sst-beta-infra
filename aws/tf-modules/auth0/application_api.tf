resource "auth0_resource_server" "application_api" {
  allow_offline_access                            = "true"
  enforce_policies                                = "false"
  identifier                                      = "${var.env_name}.monitor-your-satellites.service.gov.uk/api"
  name                                            = "api-monitor-your-satellites-${var.env_name}"
  signing_alg                                     = "RS256"
  skip_consent_for_verifiable_first_party_clients = "true"
  token_dialect                                   = "access_token"
  token_lifetime                                  = "86400"
  token_lifetime_for_web                          = "86400"
}