variable "env_name" { type = string }
variable "instances_no" { type = number }
variable "vpc_security_group_ids" {
  type = list(string)
}
variable "db_subnet_ids" {
  type = list(string)
}

variable "max_acu" {
  type = number
  default = 2.0
}

variable "default_delete_protection" {
  type = bool
  default = false
}

variable "default_monitoring_interval" {
  type = number
  default = 0
}