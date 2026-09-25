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
  default = "latest-demo"
}

variable "ses_email_from" {
  type    = string
  default = "DEMO Monitor Space Hazards <demo-notifications@monitor-space-hazards.service.gov.uk>"
}

variable "ses_email_reply_to" {
  type    = string
  default = "ukspaceagency.support@thepsc.co.uk"
}

variable "email_renderer_s3_key" {
  type = string

  validation {
    condition     = length(var.email_renderer_s3_key) > 0
    error_message = "email_renderer_s3_key must name the email-renderer bundle in the lambdas bucket; pass the backend run's email-renderer-key output."
  }
}
