variable "env_name" { type = string }
variable "cluster_log_group_name" { type = string }

variable "alarm_name" { type = string }
variable "alarm_description" { type = string }
variable "metric_namespace" { type = string }
variable "metric_name" { type = string }
variable "metric_filter_pattern" { type = string }
variable "metric_filter_name" { type = string }

variable "period_in_seconds" {
  type        = number
  default     = 60 * 60 * 12
  description = "default 12h"
}

variable "default_statistic" {
  default = "Sum"
  type    = string
}

variable "default_unit" {
  default = "Count"
  type    = string
}

variable "default_comparison_operator" {
  default = "LessThanOrEqualToThreshold"
  type    = string
}