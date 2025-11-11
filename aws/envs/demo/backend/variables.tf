variable "env_name" {
  type    = string
  default = "demo"
}

variable "app_name" {
  type    = string
  default = "api"
}

variable "image_tag" {
  type    = string
  default = "20d0962d551d110c6aa347c0e6b240b9b0e4ee98"
}

variable "ses_email_from" {
  type    = string
  default = "DEMO Monitor Space Hazards <demo-notifications@monitor-space-hazards.service.gov.uk>"
}

variable "ses_email_reply_to" {
  type    = string
  default = "ukspaceagency.support@thepsc.co.uk"
}