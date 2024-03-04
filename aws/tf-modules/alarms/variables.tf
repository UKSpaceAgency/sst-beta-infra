variable "env_name" { type = string }
variable "notifications_sender_lambda_arn" { type = string }
variable "state_machine_role_arn" { type = string }
variable "event_bridge_iam_role_arn"  { type = string }
variable "cluster_log_group_name" { type = string }