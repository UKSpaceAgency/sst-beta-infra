variable "github_token" {
  sensitive = true
}

variable "github_be_owner" {
  default = "the-psc"
}

variable "github_be_repo" {
  default = "sst-beta-python-backend"
}

variable "github_release_tag" {
  default = "latest"
}

variable "github_be_asset" {
  default = "be.zip"
}

variable "github_owner" {
  default = "UKSpaceAgency"
}

variable "github_fe_repo" {
  default = "sst-beta"
}

variable "github_fe_app_asset" {
  default = "app.zip"
}

variable "github_fe_api_asset" {
  default = "api.zip"
}