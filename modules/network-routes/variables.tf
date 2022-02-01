variable "env_tag" {
  default = "dev"
}

variable "custom_subdomain" {
  default = "www"
}

variable "app_api_route_name" {
  default = "mms-api"
}

variable "app_be_batch_route_name" {
  default = "mms-be-batch"
}

variable "app_be_interactive_route_name" {
  default = "mms-be-interactive"
}

variable "app_fe_route_name" {
  default = "monitor-my-satellites"
}

variable "app_mp_route_name" {
  default = "mms-mp"
}

variable "space" {}
