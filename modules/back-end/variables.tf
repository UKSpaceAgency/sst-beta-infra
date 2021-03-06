variable "env_tag" {
  default = "dev"
}

variable "app_spacetrack_name" {
  default = "mys-spacetrack"
}

variable "app_api_name" {
  default = "mys-api"
}

variable "app_be_buildpack" {
  default = "python_buildpack"
}

variable "app_be_memory" {
  default = 2048
}

variable "app_be_disk_quota" {
  default = 2048
}

variable "app_api_memory" {
  default = 4096
}

variable "app_api_disk_quota" {
  default = 4096
}

variable "app_be_timeout" {
  default = 300
}

variable "app_be_instances" {
  default = 1
}

variable "app_api_command" {
  default = "gunicorn -w 4 -k uvicorn.workers.UvicornWorker --preload --bind 0.0.0.0:8080 --timeout 0 app.main:app"
}

variable "app_spacetrack_command" {
  default = "python -m app.periodics.space_track_worker"
}

variable "be_build_asset" {}

variable "app_spacetrack_route" {}

variable "app_api_route" {}

variable "app_web_route" {}

variable "app_db_migration_name" {
  default = "mys-db-migration"
}

variable "app_db_migration_command" {
  default = "(alembic upgrade head && echo SUCCESS || echo FAIL) && sleep infinity"
}

variable "spacetrack_username" {}

variable "spacetrack_password" {}

variable "auth0_issuer" {}

variable "auth0_jwks_url" {}

variable "auth0_audience" {}

variable "auth0_management_client_secret" {}

variable "auth0_management_client_id" {}

variable "auth0_management_domain" {}

variable "notify_api_key" {}

variable "notify_interval" {
  default = 43200
}

variable "run_at_hour" {
  default = 21
}

variable "run_at_minute" {
  default = 0
}

variable "user_service_jwt_authentication_secret" {}

variable "user_service_reset_password_token_secret" {}

variable "user_service_verification_token_secret" {}

variable "esa_discos_access_token" {}

variable "hashid_salt" {}

variable "space" {}

variable "db" {}

variable "s3" {}

variable "logit" {}

variable "notifiers_webhook_url" {}

variable "app_sentry_dsn" {}

variable "app_spacetrack_worker_sentry_dsn" {}

variable "app_fake_data" { default = false}

