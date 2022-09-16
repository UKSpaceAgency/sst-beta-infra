variable "env_tag" {
  default = "dev"
}

variable "custom_web_subdomain" {
  default = "www"
}

variable "custom_api_subdomain" {
  default = "api"
}

variable "app_spacetrack_route_name" {
  default = "mys-spacetrack"
}
variable "app_esa_discos_route_name" {
  default = "mys-esadiscos"
}
variable "app_api_route_name" {
  default = "mys-api"
}

variable "app_web_route_name" {
  default = "mys-web"
}

variable "app_maintenance_route_name" {
  default = "mys-maintenance"
}

variable "space" {}