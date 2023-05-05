locals {
  insights_enabled = var.container_insights_enabled ? "enabled" : "disabled"
}

resource "aws_service_discovery_private_dns_namespace" "private" {
  name        = "${var.env_name}.mys.local"
  vpc         = var.custom_vpc_id
  description = "Private namespace for env ${var.env_name}"
}

resource "aws_ecs_cluster" "cluster" {
  name = "mys-${var.env_name}"
  setting {
    name  = "containerInsights"
    value = local.insights_enabled
  }
}

resource "aws_cloudwatch_log_group" "log_group_cluster" {
  name              = "/ecs/mys-${var.env_name}"
  retention_in_days = var.logs_retention_days
}