variable "env_name" { type = string }
variable "lambda_role_name" { type = string }
variable "lambda_role_arn" { type = string }
variable "lambda_policy_arn" { type = string }
variable "lambda_function_name" { type = string }
variable "lambda_handler_name" { type = string }

variable "vpc_security_group_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "env_vars" {
    type = map(any)
}

variable "s3_bucket" { type = string }
variable "s3_key" { type = string }