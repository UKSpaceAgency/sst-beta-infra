variable "env_name" { type = string }
variable "lambda_role_name" { type = string }
variable "lambda_role_arn" { type = string }
variable "lambda_policy_arn" { type = string }
variable "lambda_function_name" { type = string }
variable "lambda_handler_name" { type = string }


variable "env_vars" {
  type = map(any)
}

variable "s3_bucket" { type = string }
variable "s3_key" { type = string }


variable "lambda_memory_size" {
  type = number
  default = 128
}

variable "runtime" {
  type = string
  default = "python3.11"
}

variable "timeout" {
  type = number
  default = 30
}