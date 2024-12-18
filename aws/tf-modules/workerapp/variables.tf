variable "env_name" { type = string }
variable "app_name" { type = string }
variable "ecr_app_name" { type = string }
variable "app_cpu" { type = number }
variable "app_mem" { type = number }
variable "app_instances_num" { type = number }
variable "image_tag" { type = string }
variable "ecs_task_role_arn" { type = string }
variable "ecs_execution_role_arn" { type = string }
variable "awslogs_group" { type = string }
variable "custom_vpc_id" { type = string }
variable "worker_command" { type = list(string) }

variable "default_sg_id" { type = string }

variable "public_subnet_ids" {
  type = list(string)
}
variable "ecs_cluster_arn" { type = string }
variable "env_vars" {
  type = list(object({
    name  = string
    value = string
  }))
}

variable "secret_env_vars" {
  type = list(object({
    name      = string
    valueFrom = string
  }))
}

variable "enable_ecs_execute" {
  type    = bool
  default = false
}

variable "ecs_events_role_arn" {
  type = string
}

variable "ecs_events_role_id" {
  type = string
}

variable "cron_expression" {
  type = string
}

variable "default_capacity_provider" {
  default = "FARGATE"
  type = string
}