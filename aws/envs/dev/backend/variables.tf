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

# Who a human may release caught dev mail to from the Mailpit UI. This list IS the blast radius:
# Release refuses any address not on it, so the UI password on its own cannot turn the catcher into
# an open relay through our SES identity. Nothing leaves on its own: a message sits in Mailpit until
# somebody opens it and clicks Release, so a dev load test still sends nothing outbound.
# Each released copy carries the original recipients in its To/Cc headers and the original body.
# This repo is public and its Actions logs are world readable, so real addresses do not belong
# here. The deploy workflow passes them in from the MAILPIT_RELEASE_RECIPIENTS environment secret.
# Empty means no relay host, so Mailpit does not offer Release at all and mail stays in the VPC.
variable "mailpit_release_allowed_recipients" {
  type    = list(string)
  default = []

  # Unmarked, the deploy step's plan output prints these in clear text. Marking it redacts the
  # whole mailpit container_definitions, which costs little: the rest of that blob is built from
  # literals in mailpit.tf, so git already shows what it contains.
  sensitive = true

  # These entries are escaped and anchored into a Go regexp, not parsed as addresses, so a regex
  # written here does not do what its author expects: mailpit.tf escapes every metacharacter, so
  # `.*@thepsc.co.uk` becomes a literal that matches nothing and Release then fails at the point of
  # use with "do not match the allowlist". Rejecting it at plan time is the difference between a
  # clear error and a control that silently allows nobody. No comma either, which would otherwise
  # read as two addresses to a human and one unmatchable literal to Mailpit. Deliberately narrower
  # than Go's mail.ParseAddress, which the Release handler applies to the address a human types and
  # which would accept display names, quoted local parts and non-ASCII (RFC 6532) addresses.
  validation {
    condition     = alltrue([for r in var.mailpit_release_allowed_recipients : can(regex("^[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+(\\.[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+)*@[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)+$", r))])
    error_message = "Each entry must be a bare email address, for example name@example.com."
  }
}
