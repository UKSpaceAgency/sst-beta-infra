locals {
  insights_enabled = var.container_insights_enabled ? "enabled" : "disabled"
}

resource "aws_service_discovery_http_namespace" "private" {
  name        = "internal"
  description = "Private namespace for env ${var.env_name}"
}

resource "aws_ecs_cluster" "cluster" {
  name = "mys-${var.env_name}"
  setting {
    name  = "containerInsights"
    value = local.insights_enabled
  }
  service_connect_defaults {
    namespace = aws_service_discovery_http_namespace.private.arn
  }
}

resource "aws_cloudwatch_log_group" "log_group_cluster" {
  name              = "/ecs/mys-${var.env_name}"
  retention_in_days = var.logs_retention_days
}

resource "aws_ecs_cluster_capacity_providers" "capacity_provider" {
  cluster_name = aws_ecs_cluster.cluster.name
  capacity_providers = var.default_capacity_provider_list
}