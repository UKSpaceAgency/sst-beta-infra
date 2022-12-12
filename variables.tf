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

variable "be_asset" {
  default = "be.zip"
}

variable "app_asset" {
  default = "app.zip"
}

variable "api_asset" {
  default = "api.zip"
}

variable "github_token" {}

variable "spacetrack_username" {}

variable "spacetrack_password" {}

variable "i18nexus_api_key" {}

variable "cosmic_bucket_slug" {}

variable "cosmic_read_key" {}

variable "cosmic_preview_secret" {}

variable "piwik_id" {
  default = ""
}

variable "nextauth_secret" {}

variable "auth0_issuer" {}

variable "auth0_client_id" {}

variable "auth0_client_secret" {}

variable "auth0_jwks_url" {}

variable "auth0_audience" {}

variable "auth0_management_client_secret" {}

variable "auth0_management_client_id" {}

variable "auth0_management_domain" {}

variable "notify_api_key" {}

variable "user_service_jwt_authentication_secret" {}

variable "user_service_reset_password_token_secret" {}

variable "user_service_verification_token_secret" {}

variable "esa_discos_access_token" {}

variable "notifiers_webhook_url" {}

variable "app_fake_data" { default = false }

variable "hashid_salt" {}

variable "spacetrack_run_at_hour" {}

variable "spacetrack_run_at_minute" {}

variable "maintenance_mode" {
  default = false
}

variable "app_sentry_dsn" {}

variable "app_sentry_sample_rate" {}

variable "app_spacetrack_worker_sentry_dsn" {}

variable "esa_repeat_every_seconds" {}

variable "esa_run_at_hour" {}

variable "esa_run_at_minutes" {}

variable "esa_sentry_dsn" {}

variable "spacetrack_repeat_every_seconds" {}

variable "notifications_repeat_every_seconds" {}

variable "notifications_sentry_dsn" {}

variable "notify_contact_analyst_email" {}
