variable "env_tag" {
  default = "dev"
}

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

variable "github_fe_app_asset" {
  default = "app.zip"
}

variable "github_fe_api_asset" {
  default = "api.zip"
}

variable "be_app" {}

variable "space" {}

variable "db" {}

variable "logit" {}

variable "app_api_name" {
  default = "mms-api"
}

variable "app_api_memory" {
  default = 4096
}

variable "app_api_disk_quota" {
  default = 6144
}

variable "app_api_timeout" {
  default = 300
}

variable "app_api_instances" {
  default = 1
}

variable "app_api_buildpack" {
  default = "nodejs_buildpack"
}

variable "app_api_command" {
  default = "node dist/apps/api/main.js"
}

variable "app_api_strategy" {
  default = "blue-green"
}

variable "app_api_route" {}

variable "app_be_route" {}

variable "app_fe_route" {}

variable "iron_name" {}

variable "iron_password" {}

variable "app_fe_name" {
  default = "mms-fe"
}

variable "app_fe_buildpack" {
  default = "nodejs_buildpack"
}

variable "app_fe_command" {
  default = "npm run start"
}

variable "app_fe_memory" {
  default = 4096
}

variable "app_fe_disk_quota" {
  default = 4096
}

variable "app_fe_instances" {
  default = 1
}

variable "app_fe_strategy" {
  default = "blue-green"
}

variable "internal_domain" {}

variable "cloudapps_domain" {}

variable "custom_domain" {}

variable "custom_domain_flag" {
  default = "false"
}