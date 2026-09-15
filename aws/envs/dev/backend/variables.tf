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

# Who gets a copy of dev mail caught by Mailpit. This list IS the blast radius: copies go
# to these addresses and nowhere else, whatever the message was addressed to, and each copy
# still carries the original recipients in its To/Cc headers and the original body.
# This repo is public, so real addresses do not belong in this default. The deploy workflow
# passes them in from the MAILPIT_FORWARD_RECIPIENTS environment secret.
# Empty means forwarding is off and mail stays in the VPC. Emptying it takes a redeploy,
# so treat it as a between-runs switch rather than an incident-time one.
variable "mailpit_forward_recipients" {
  type    = list(string)
  default = []

  # Mailpit exits at startup on an address it cannot parse rather than skipping that one
  # recipient, and the container is essential, so a typo here takes the catcher down and
  # hangs the deploy on wait_for_steady_state. Deliberately stricter than Mailpit's own
  # check: bare addresses only, dotted domain, so nothing it would reject gets through.
  validation {
    condition     = alltrue([for r in var.mailpit_forward_recipients : can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", r))])
    error_message = "Each entry must be a bare email address, for example name@example.com."
  }
}
