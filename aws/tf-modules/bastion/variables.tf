variable "env_name" { type = string }
variable "vpc_security_group_ids" {
  type = list(string)
}
variable "public_subnet_id" {}
