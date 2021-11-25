# These settings are defaults and should be overridden with TF_VARS

variable "api_url" {
  default = "https://api.london.cloud.service.gov.uk"
}

variable "paas_app_route_name" {}

variable "paas_app_api_route_name" {
  default = "monitor-my-satellites-api"
}

variable "paas_app_fe_name" {
  default = "monitor-my-satellites-fe"
}

variable "paas_app_fe_memory" {
  default = 1024
}

variable "paas_app_fe_disk_quota" {
  default = 2048
}

variable "paas_app_fe_instances" {
  default = 1
}

variable "paas_app_fe_buildpack" {
  default = "staticfile_buildpack"
}

variable "paas_app_fe_build_artefact" {
  default = "https://github.com/UKSpaceAgency/sst-beta/releases/download/latest/sst.zip"
}

variable "paas_app_fe_proxy_conf" {
  default = "nginx/conf/includes/proxy.conf"
}

variable "paas_app_api_name" {
  default = "monitor-my-satellites-api"
}

variable "paas_app_api_memory" {
  default = 1024
}

variable "pass_app_api_disk_quota" {
  default = 2048
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

variable "paas_app_api_build_artefact" {
  default = "https://github.com/UKSpaceAgency/sst-beta/releases/download/latest/api.zip"
}

variable "paas_app_api_command" {
  default = "node dist/apps/api/main.js"
}

variable "paas_db_name" {
  default = "monitor-my-satellites-db"
}

variable "paas_db_service" {
  default = "postgres"
}

variable "paas_db_plan" {
  default = "tiny-unencrypted-13-high-iops"
}

variable "paas_s3_name" {
  default = "monitor-my-satellites-s3"
}

variable "paas_s3_service" {
  default = "aws-s3-bucket"
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

variable "github_release_tag" {
  default = "latest"
}

variable "github_fe_api_asset" {
  default = "api.zip"
}

variable "github_fe_sst_asset" {
  default = "sst.zip"
}
