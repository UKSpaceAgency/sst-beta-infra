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
  default = "c72155a3b28ede1821ec8d4f4e1505017d3552f"
}

variable "ses_email_from" {
  type    = string
  default = "Monitor Space Hazards <notifications@monitor-space-hazards.service.gov.uk>"
}

variable "ses_email_reply_to" {
  type    = string
  default = "monitorspacehazards@ukspaceagency.gov.uk"
}