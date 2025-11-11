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

output "s3_bucket_arn" {
  value = module.s3.bucket_arn
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "lambdas_bucket_id" {
  value = module.s3.lambdas_bucket_id
}

output "lambda_iam_policy_vpc_arn" {
  value = module.iam.lambda_iam_policy_vpc_arn
}

output "lambda_iam_policy_public_arn" {
  value = module.iam.lambda_iam_policy_public_arn
}

output "state_machine_iam_role_arn" {
  value = module.iam.state_machine_iam_role_arn
}

output "event_bridge_iam_role_arn" {
  value = module.iam.event_bridge_invoke_sfn_iam_role_arn
}


output "vpc_secrets_manager_endpoint_arn" {
  value = module.network.vpc_secrets_manager_endpoint_arn
}

output "s3_reentry_bucket_id" {
  value = module.s3.reentry_bucket_id
}

output "s3_reentry_bucket_arn" {
  value = module.s3.reentry_bucket_arn
}

output "data-cache-client-sqs" {
  value = module.data-cache-sqs.data-cache-sqs-arn
}