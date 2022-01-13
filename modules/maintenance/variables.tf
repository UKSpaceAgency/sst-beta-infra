variable "env_tag" {
  default = "dev"
}

variable "app_name" {
  default = "mms-mp"
}

variable "app_memory" {
  default = 64
}

variable "app_buildpack" {
  default = "staticfile_buildpack"
}

variable "build_asset" {
  default = "mp.zip"
}

variable "active" {
  default = true
}

variable "app_route" {}

variable "space" {}
