module "frontend" {
  source                 = "../../../tf-modules/ecsapp"
  env_name               = var.env_name
  alb_name               = data.terraform_remote_state.stack.outputs.alb_name
  app_alb_priority       = 5
  app_cpu                = 512
  app_instances_num      = 1
  app_mem                = 1024
  app_name               = var.app_name
  ecr_app_name           = "frontend"
  app_port_num           = 3000
  awslogs_group          = data.terraform_remote_state.stack.outputs.cluster_log_group_name
  custom_vpc_id          = data.terraform_remote_state.stack.outputs.custom_vpc_id
  default_sg_id          = data.terraform_remote_state.stack.outputs.default_sg_id
  ecs_cluster_arn        = data.terraform_remote_state.stack.outputs.cluster_arn
  ecs_execution_role_arn = data.terraform_remote_state.stack.outputs.ecs_execution_role_arn
  ecs_task_role_arn      = data.terraform_remote_state.stack.outputs.ecs_task_role_arn
  public_subnet_ids      = data.terraform_remote_state.stack.outputs.public_subnet_ids
  env_vars = [
    { "name" : "APP_NAME", "value" : "Web App (${var.image_tag})" },
    { "name" : "APP_ENV", "value" : var.env_name },
    { "name" : "API_URL", "value" : "http://backend.internal:8080" },
    { "name" : "HOSTNAME", "value" : "0.0.0.0" },
  ]
  secret_env_vars = [
    {
      "name" : "NEXTAUTH_SECRET",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:nextauthSecret::"
    },
    {
      "name" : "NEXTAUTH_URL",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:nextauthUrl::"
    },
    {
      "name" : "AUTH_TRUST_HOST",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:nextauthUrl::"
    },
    {
      "name" : "AUTH0_BASEURL",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:auth0BaseUrl::"
    },
    {
      "name" : "AUTH0_AUDIENCE",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:auth0Audience::"
    },
    {
      "name" : "AUTH0_CLIENT_ID",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:auth0ClientId::"
    },
    {
      "name" : "AUTH0_CLIENT_SECRET",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:auth0ClientSecret::"
    },
    {
      "name" : "COSMIC_BUCKET_SLUG",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:cosmicBucketSlug::"
    },
    {
      "name" : "COSMIC_READ_KEY",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:cosmicReadKey::"
    },
    {
      "name" : "FEEDBACK_URL",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:feedbackUrl::"
    },
  ]
  healthcheck_subpath = "/api/health"
  image_tag           = var.image_tag
  route53_domain      = local.local_r53_domain
  enable_ecs_execute  = true
}