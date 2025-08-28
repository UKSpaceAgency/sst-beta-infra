variable "env_name" {
  type    = string
  default = "dev"
}

variable "app_name" {
  type    = string
  default = "api"
}

variable "image_tag" {
  type    = string
  default = "31125abdfca179842d03c28b8f41de62ba563f27"
}

variable "ses_email_from" {
  type    = string
  default = "DEV Monitor Space Hazards <dev-notifications@monitor-space-hazards.service.gov.uk>"
}

variable "ses_email_reply_to" {
  type    = string
  default = "ukspaceagency.support@thepsc.co.uk"
}