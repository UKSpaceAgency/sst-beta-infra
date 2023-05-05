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

variable "route53_domain" {
  type    = string
  default = "awsdev.monitor-your-satellites.service.gov.uk"
}