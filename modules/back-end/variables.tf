variable "env_tag" {
  default = "dev"
}

variable "app_be_name" {
  default = "mms-be"
}

variable "app_be_buildpack" {
  default = "python_buildpack"
}

variable "app_be_memory" {
  default = 4096
}

variable "app_be_disk_quota" {
  default = 4096
}

variable "app_be_timeout" {
  default = 300
}

variable "app_be_instances" {
  default = 1
}

variable "app_be_command" {
  default = "uvicorn app.main:app --port 8080 --host 0.0.0.0 --workers 1"
}

variable "be_build_asset" {}

variable "app_be_route" {}

variable "app_fe_route" {}

variable "app_db_migration_name" {
  default = "mms-db-migration"
}

variable "app_db_migration_command" {
  default = "(alembic upgrade head && echo SUCCESS || echo FAIL) && sleep infinity"
}

variable "spacetrack_username" {}

variable "spacetrack_password" {}

variable "iron_name" {}

variable "iron_password" {}

variable "notify_api_key" {}

variable "notify_interval" {
  default = 43200
}

variable "user_service_jwt_authentication_secret" {}

variable "user_service_reset_password_token_secret" {}

variable "user_service_verification_token_secret" {}

variable "space" {}

variable "db" {}

variable "s3" {}

variable "logit" {}