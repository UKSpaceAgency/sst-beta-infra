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
# This repo is public and its Actions logs are world readable, so real addresses do not belong
# here. The deploy workflow passes them in from the MAILPIT_FORWARD_RECIPIENTS environment secret.
# Empty means forwarding is off and mail stays in the VPC. Emptying it takes a redeploy,
# so treat it as a between-runs switch rather than an incident-time one.
variable "mailpit_forward_recipients" {
  type    = list(string)
  default = []

  # Unmarked, the deploy step's plan output prints these in clear text. Marking it redacts the
  # whole mailpit container_definitions, which costs little: the rest of that blob is built from
  # literals in mailpit.tf, so git already shows what it contains.
  sensitive = true

  # Mailpit exits at startup on an address it cannot parse rather than skipping that one
  # recipient, and the container is essential, so a typo here takes the catcher down and
  # hangs the deploy on wait_for_steady_state. Mailpit splits MP_SMTP_FORWARD_TO on commas
  # and runs each entry through Go's mail.ParseAddress, which needs two things this pattern
  # gives it: every character class below sits inside its isAtext, and dots only ever fall
  # between non-empty runs, since it rejects a leading, trailing or doubled dot. Moving the
  # dot into the character class would keep the first and lose the second. No comma either,
  # which would otherwise smuggle a second bogus recipient in through the join. Deliberately
  # narrower than Mailpit, which would accept display names, quoted local parts and non-ASCII
  # (RFC 6532) addresses.
  validation {
    condition     = alltrue([for r in var.mailpit_forward_recipients : can(regex("^[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+(\\.[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+)*@[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)+$", r))])
    error_message = "Each entry must be a bare email address, for example name@example.com."
  }
}
