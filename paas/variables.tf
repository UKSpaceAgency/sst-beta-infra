# These settings are defaults and should be overridden with TF_VARS

variable "api_url" {
  default = "https://api.london.cloud.service.gov.uk"
}

variable "paas_app_route_name" {}

variable "paas_app_api_route_name" {
  default = "monitor-my-satellites-api"
}

variable "paas_app_be_route_name" {
  default = "monitor-my-satellites-be"
}

variable "paas_app_fe_name" {
  default = "monitor-my-satellites-fe"
}

variable "paas_app_fe_memory" {
  default = 4096
}

variable "paas_app_fe_disk_quota" {
  default = 4096
}

variable "paas_app_fe_instances" {
  default = 1
}

variable "paas_app_fe_buildpack" {
  default = "nodejs_buildpack"
}

variable "paas_app_fe_command" {
  default = "npm run start"
}

variable "paas_app_fe_strategy" {
  default = "blue-green"
}

variable "paas_app_api_name" {
  default = "monitor-my-satellites-api"
}

variable "paas_app_api_memory" {
  default = 4096
}

variable "pass_app_api_disk_quota" {
  default = 6144
}

variable "paas_app_api_instances" {
  default = 1
}

variable "paas_app_api_timeout" {
  default = 300
}

variable "paas_app_api_buildpack" {
  default = "nodejs_buildpack"
}

variable "paas_app_api_command" {
  default = "node dist/apps/api/main.js"
}

variable "paas_app_api_strategy" {
  default = "blue-green"
}

variable "paas_app_be_name" {
  default = "monitor-my-satellites-be"
}

variable "paas_app_be_memory" {
  default = 4096
}

variable "pass_app_be_disk_quota" {
  default = 4096
}

variable "paas_app_be_instances" {
  default = 1
}

variable "paas_app_be_timeout" {
  default = 300
}

variable "paas_app_be_buildpack" {
  default = "python_buildpack"
}

variable "paas_app_be_command" {
  default = "uvicorn app.main:app --port 8080 --host 0.0.0.0 --workers 4"
}

variable "paas_app_db_migration_name" {
  default = "monitor-my-satellites-db-migration"
}

variable "paas_app_db_migration_command" {
  default = "(alembic upgrade head && echo SUCCESS || echo FAIL) && sleep infinity"
}

variable "paas_db_name" {
  default = "monitor-my-satellites-db"
}

variable "paas_db_service" {
  default = "postgres"
}

variable "paas_db_plan" {
  default = "small-13"
}

variable "paas_s3_name" {
  default = "monitor-my-satellites-s3"
}

variable "paas_s3_service" {
  default = "aws-s3-bucket"
}

variable "paas_custom_domain_flag" {
  default = false
}

variable "paas_custom_subdomain" {
  default = "www"
}

variable "paas_org_name" {
  default = "uk-space-agency-space-surveillance-and-tracking"
}

variable "paas_space" {
  default = "sandbox"
}

variable "paas_password" {
  sensitive = true
}

variable "paas_username" {}

variable "github_token" {
  sensitive = true
}

variable "github_owner" {
  default = "UKSpaceAgency"
}

variable "github_fe_repo" {
  default = "sst-beta"
}

variable "github_thepsc" {
  default = "the-psc"
}

variable "github_be_repo" {
  default = "sst-beta-python-backend"
}

variable "github_release_tag" {
  default = "latest"
}

variable "github_fe_api_asset" {
  default = "api.zip"
}

variable "github_fe_app_asset" {
  default = "app.zip"
}

variable "github_be_asset" {
  default = "be.zip"
}

variable "logit_service_name" {
  default = "logit-ssl-drain"
}

variable "logit_endpoint" {}

variable "spacetrack_username" {}

variable "spacetrack_password" {}

variable "paas_app_iron_name" {}

variable "paas_app_iron_password" {}

variable "notify_api_key" {}

variable "user_service_jwt_authentication_secret" {}

variable "user_service_reset_password_token_secret" {}

variable "user_service_verification_token_secret" {}

variable "paas_app_mp_name" {
  default = "monitor-my-satellites-mp"
}

variable "paas_app_mp_buildpack" {
  default = "staticfile_buildpack"
}

variable "paas_mp_asset" {
  default = "mp.zip"
}