variable "env_name" { type = string }
variable "lambda_role_name" { type = string }
variable "lambda_role_arn" { type = string }
variable "lambda_policy_arn" { type = string }
variable "lambda_function_name" { type = string }

variable "env_vars" {
  type = map(any)
}

variable "ecr_image" { type = string }