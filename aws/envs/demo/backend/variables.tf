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
  default = "6f2cf579eee22f9df0a383edd47f95ff5c9c6ed0"
}

variable "ses_email_from" {
  type    = string
  default = "DEMO Monitor Space Hazards <demo-notifications@monitor-space-hazards.service.gov.uk>"
}

variable "ses_email_reply_to" {
  type    = string
  default = "ukspaceagency.support@thepsc.co.uk"
}