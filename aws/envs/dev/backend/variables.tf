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
  default = "908719e50ff3d9ad5d0e8f90bb1f56a714e83bc3"
}

variable "ses_email_from" {
  type    = string
  default = "DEV Monitor Space Hazards <dev-notifications@monitor-space-hazards.service.gov.uk>"
}

variable "ses_email_reply_to" {
  type    = string
  default = "ukspaceagency.support@thepsc.co.uk"
}

variable "data_cache_sqs_arn" {
  type = string
  default = "arn:aws:sqs:eu-west-2:915338536460:temp-data-cache-dev"
}