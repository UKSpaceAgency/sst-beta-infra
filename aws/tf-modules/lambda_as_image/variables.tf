variable "env_name" { type = string }
variable "lambda_role_name" { type = string }
variable "lambda_role_arn" { type = string }
variable "lambda_policy_arn" { type = string }
variable "lambda_function_name" { type = string }

variable "env_vars" {
  type = map(any)
}

variable "ecr_image" { type = string }

variable "image_command" {
  type    = list(string)
  default = null
}

variable "vpc_security_group_ids" {
  type    = list(string)
  default = null
}

variable "private_subnet_ids" {
  type    = list(string)
  default = null
}

variable "default_timeout" {
  type    = number
  default = 900
}

variable "memory_size" {
  type    = number
  default = 4096
}