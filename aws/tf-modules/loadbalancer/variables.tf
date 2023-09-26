variable "env_name" { type = string }
variable "public_subnet_ids" {
  type = list(string)
}

variable "allow_tls_only_sg_id" { type = string }
variable "default_sg_id" { type = string }
variable "domain_cert_arn" { type = string }