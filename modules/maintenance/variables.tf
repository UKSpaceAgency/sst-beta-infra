variable "env_tag" {
  default = "dev"
}

variable "app_name" {
  default = "mms-mp"
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

variable "space" {}
