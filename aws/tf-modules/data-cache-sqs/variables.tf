variable "data-cache-sns-topic-arn" {
  type = string
}

variable "env_name" { type = string }

variable "sqs_retention_seconds" {
  type = number
}

variable "sqs_visibility_timeout_seconds" {
  type = number
}