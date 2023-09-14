output "alb_name" {
  value = module.alb.alb_name
}

output "cluster_log_group_name" {
  value = module.ecs.cluster_log_group_name
}

output "custom_vpc_id" {
  value = module.network.custom_vpc_id
}

output "default_sg_id" {
  value = module.network.default_sg_id
}

output "cluster_arn" {
  value = module.ecs.cluster_arn
}

output "cluster_service_connect_namespace_arn" {
  value = module.ecs.cluster_service_connect_namespace_arn
}

output "ecs_execution_role_arn" {
  value = module.iam.ecs_execution_role_arn
}

output "ecs_task_role_arn" {
  value = module.iam.ecs_task_role_arn
}

output "ecs_events_role_arn" {
  value = module.iam.ecs_events_role_arn
}

output "ecs_events_role_id" {
  value = module.iam.ecs_events_role_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "s3_bucket_id" {
  value = module.s3.bucket_id
}

output "deployment_hist_bucket_id" {
  value = module.s3.deployment_hist_bucket_id
}

output "route53_domain" {
  value = var.route53_domain
}