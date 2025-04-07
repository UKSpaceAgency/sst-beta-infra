variable "env_name" {
  type    = string
  default = "prod"
}

variable "app_name" {
  type    = string
  default = "api"
}

variable "image_tag" {
  type    = string
  default = "latest-prod"
}

variable "ses_email_from" {
  type    = string
  default = "Monitor Space Hazards <notifications@monitor-space-hazards.service.gov.uk>"
}

variable "ses_email_reply_to" {
  type    = string
  default = "monitorspacehazards@ukspaceagency.gov.uk"
}