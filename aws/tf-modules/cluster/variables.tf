variable "env_name" { type = string }
variable "custom_vpc_id" { type = string }
variable "logs_retention_days" {
  type = number
  default = 30
}
variable "container_insights_enabled" {type = bool}