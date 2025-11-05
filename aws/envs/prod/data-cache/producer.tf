module "data_cache_producer" {
  source                 = "../../../tf-modules/ecsapp_no_sc"
  env_name               = var.env_name
  alb_name               = data.terraform_remote_state.stack.outputs.alb_name
  app_alb_priority       = 20
  app_cpu                = 256
  app_instances_num      = 1
  app_mem                = 512
  app_name               = "data-cache-producer"
  ecr_app_name           = "data-cache"
  app_port_num           = 8080
  default_capacity_provider = "FARGATE"
  awslogs_group          = data.terraform_remote_state.stack.outputs.cluster_log_group_name
  custom_vpc_id          = data.terraform_remote_state.stack.outputs.custom_vpc_id
  default_sg_id          = data.terraform_remote_state.stack.outputs.default_sg_id
  ecs_cluster_arn        = data.terraform_remote_state.stack.outputs.cluster_arn
  ecs_execution_role_arn = data.terraform_remote_state.stack.outputs.ecs_execution_role_arn
  ecs_task_role_arn      = data.terraform_remote_state.stack.outputs.ecs_task_role_arn
  public_subnet_ids      = data.terraform_remote_state.stack.outputs.public_subnet_ids
  env_vars = [
    { "name" : "APP_NAME", "value" : "Data Cache Producer (${var.image_tag})" },
    { "name" : "APP_ENVIRONMENT", "value" : var.env_name },
    { "name" : "BUCKET_NAME", "value" : data.terraform_remote_state.stack.outputs.data_cache_bucket_id },
  ]
  secret_env_vars = [
    {
      "name" : "SPACE_TRACK_PASSWORD",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:spacetrackPassword::"
    },
    {
      "name" : "SPACE_TRACK_IDENTITY",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:spacetrackIdentity::"
    },
    {
      "name" : "SPACE_TRACK_RAW_BASE_URL",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:spacetrackBaseUrl::"
    },
    {
      "name" : "SPACE_TRACK_API_RATE_LIMIT_PER_MINUTE",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:spacetrackAPIRateLimitPerMinute::"
    },
    {
      "name" : "SPACE_TRACK_CDMS_ITERATOR_LIMIT",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:spacetrackCdmsIteratorLimit::"
    },
    {
      "name" : "ESA_DISCOS_ACCESS_TOKEN",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:esaDiscosAccessToken::"
    }
  ]
  healthcheck_subpath = "/healthcheck"
  image_tag           = var.image_tag
  route53_domain      = local.local_r53_domain
  enable_ecs_execute  = true
}