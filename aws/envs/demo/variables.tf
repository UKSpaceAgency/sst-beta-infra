variable "env_name" {
  type    = string
  default = "demo"
}

variable "route53_domain" {
  type    = string
  default = "demo.monitor-space-hazards.service.gov.uk"
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