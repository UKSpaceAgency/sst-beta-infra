variable "env_name" {
  type    = string
  default = "prod"
}

variable "route53_domain" {
  type    = string
  default = ".monitor-your-satellites.service.gov.uk"
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