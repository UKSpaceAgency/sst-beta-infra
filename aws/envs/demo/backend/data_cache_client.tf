module "data_cache_client" {
  source                 = "../../../tf-modules/ecsapp_no_sc"
  env_name               = var.env_name
  alb_name               = data.terraform_remote_state.stack.outputs.alb_name
  app_alb_priority       = 15
  app_cpu                = 512
  app_instances_num      = 1
  app_mem                = 1024
  app_name               = "data-cache-client"
  ecr_app_name           = "backend"
  app_port_num           = 8080
  default_capacity_provider = "FARGATE_SPOT"
  awslogs_group          = data.terraform_remote_state.stack.outputs.cluster_log_group_name
  custom_vpc_id          = data.terraform_remote_state.stack.outputs.custom_vpc_id
  default_sg_id          = data.terraform_remote_state.stack.outputs.default_sg_id
  ecs_cluster_arn        = data.terraform_remote_state.stack.outputs.cluster_arn
  ecs_execution_role_arn = data.terraform_remote_state.stack.outputs.ecs_execution_role_arn
  ecs_task_role_arn      = data.terraform_remote_state.stack.outputs.ecs_task_role_arn
  public_subnet_ids      = data.terraform_remote_state.stack.outputs.public_subnet_ids
  custom_command = ["poetry", "run", "uvicorn", "--host=0.0.0.0", "--port=8080", "app.cache_consumer.main:app", "--workers", "1"]
  env_vars = [
    { "name" : "APP_NAME", "value" : "Data Cache Client (${var.image_tag})" },
    { "name" : "APP_ENVIRONMENT", "value" : var.env_name },
    { "name" : "S3_SQS_QUEUE_ARN", "value" : "arn:aws:sqs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:data-cache-client-${var.env_name}"},
  ]
  secret_env_vars = [
    {
      "name" : "DATABASE_URL",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:databaseUrl::"
    },
    {
      "name" : "HASHID_SALT",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:hashSaltId::"
    }
  ]
  healthcheck_subpath = "/healthcheck"
  image_tag           = var.image_tag
  route53_domain      = local.local_r53_domain
  enable_ecs_execute  = true
}

module "data_cache_scaling" {
  source = "../../../tf-modules/data-cache-scaling"
  env_name = var.env_name
}