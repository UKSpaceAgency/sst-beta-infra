variable "env_tag" {
  default = "dev"
}

variable "be_app" {}

variable "space" {}

variable "db" {}

variable "logit" {}

variable "fe_build_asset" {}

variable "app_be_route" {}

variable "app_fe_route" {}

variable "iron_name" {}

variable "iron_password" {}

variable "piwik_id" {}

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
  default = "none"
}

variable "internal_domain" {}

variable "cloudapps_domain" {}

variable "custom_domain" {}

variable "custom_domain_flag" {
  default = "false"
}