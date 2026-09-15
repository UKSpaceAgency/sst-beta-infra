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
  default = "latest"
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
  type    = string
  default = "arn:aws:sqs:eu-west-2:915338536460:data-cache-client-dev"
}

# Everyone who receives a copy of dev mail caught by Mailpit. This list IS the blast
# radius: forwarded copies go here and nowhere else, whatever the original message was
# addressed to. Empty means forwarding is off and mail stays in the VPC; set it to []
# before a dev load test.
variable "mailpit_forward_recipients" {
  type    = list(string)
  default = []
}