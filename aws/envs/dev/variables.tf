variable "env_name" {
  type    = string
  default = "dev"
}

variable "route53_domain" {
  type    = string
  default = "dev.monitor-space-hazards.service.gov.uk"
}

variable "mys_route53_domain" {
  type    = string
  default = "dev.monitor-your-satellites.service.gov.uk"
}

#variable "auth_client_id" {
#  type    = string
#  sensitive = true
#}
#
#variable "auth_client_secret" {
#  type    = string
#  sensitive = true
#}