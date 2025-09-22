variable "env_name" { type = string }
variable "us_east_1_cert_arn" {
  type = string
}

variable "primary_hosted_zone_id" {
  type = string
}
variable "route53_domain" { type = string }

variable "alb_domain_name" {
  type = string
}

variable "cdn_name" {
  type = string
  default = "www"
}
