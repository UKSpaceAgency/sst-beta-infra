# These settings are defaults and should be overridden with TF_VARS

variable "paas_api_url" {
  default = "https://api.london.cloud.service.gov.uk"
}

variable "paas_space" {}

variable "paas_org_name" {
  default = "uk-space-agency-space-surveillance-and-tracking"
}

variable "paas_username" {}

variable "paas_password" {
  sensitive = true
}

variable "logit_service_url" {}

variable "env_tag" {}

variable "github_token" {}

variable "spacetrack_username" {}

variable "spacetrack_password" {}

variable "iron_name" {}

variable "iron_password" {}

variable "notify_api_key" {}

variable "user_service_jwt_authentication_secret" {}

variable "user_service_reset_password_token_secret" {}

variable "user_service_verification_token_secret" {}