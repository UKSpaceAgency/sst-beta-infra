output "cluster_log_group_name" {
  value = aws_cloudwatch_log_group.log_group_cluster.name
}

output "cluster_arn" {
  value = aws_ecs_cluster.cluster.arn
}

output "cluster_service_connect_namespace_arn" {
  value = aws_service_discovery_http_namespace.private.arn
}