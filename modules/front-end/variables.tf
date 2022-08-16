variable "env_tag" {
  default = "dev"
}

variable "space" {}

variable "db" {}

variable "logit" {}

variable "fe_build_asset" {}

variable "app_api_route" {}

variable "app_web_route" {}

variable "app_api-gov_route" {}

variable "app_web-gov_route" {}

variable "nextauth_secret" {}

variable "auth0_issuer" {}

variable "auth0_client_id" {}

variable "auth0_client_secret" {}

variable "piwik_id" {}

variable "i18nexus_api_key" {}

variable "cosmic_bucket_slug" {}

variable "cosmic_read_key" {}

variable "cosmic_preview_secret" {}

variable "app_web_name" {
  default = "mys-web"
}

variable "app_web_buildpack" {
  default = "nodejs_buildpack"
}

variable "app_web_command" {
  default = "npm run start"
}

variable "app_web_memory" {
  default = 4096
}

variable "app_web_disk_quota" {
  default = 4096
}

variable "app_web_instances" {
  default = 1
}

variable "app_web_strategy" {
  default = "none"
}

variable "auth0_audience" {}
