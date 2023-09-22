module "backend" {
  source                 = "../../../tf-modules/ecsapp"
  env_name               = var.env_name
  alb_name               = data.terraform_remote_state.stack.outputs.alb_name
  app_alb_priority       = 10
  app_cpu                = 512
  app_instances_num      = 2
  app_mem                = 1024
  app_name               = var.app_name
  ecr_app_name           = "backend"
  app_port_num           = 8080
  awslogs_group          = data.terraform_remote_state.stack.outputs.cluster_log_group_name
  custom_vpc_id          = data.terraform_remote_state.stack.outputs.custom_vpc_id
  default_sg_id          = data.terraform_remote_state.stack.outputs.default_sg_id
  ecs_cluster_arn        = data.terraform_remote_state.stack.outputs.cluster_arn
  ecs_execution_role_arn = data.terraform_remote_state.stack.outputs.ecs_execution_role_arn
  ecs_task_role_arn      = data.terraform_remote_state.stack.outputs.ecs_task_role_arn
  public_subnet_ids      = data.terraform_remote_state.stack.outputs.public_subnet_ids
  env_vars = [
    { "name" : "APP_NAME", "value" : "API Backend (${var.image_tag})" },
    { "name" : "APP_ENVIRONMENT", "value" : var.env_name },
    { "name" : "APP_FRONTEND_URL", "value" : "https://www.${local.local_r53_domain}" }, //todo
    { "name" : "APP_SENTRY_SAMPLE_RATE", "value" : "0.05" },
    { "name" : "S3_BUCKET_NAME", "value" : data.terraform_remote_state.stack.outputs.s3_bucket_id },
  ]
  secret_env_vars = [
    {
      "name" : "DATABASE_URL",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:databaseUrl::"
    },
    {
      "name" : "AUTH0_ISSUER",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:auth0Issuer::"
    },
    {
      "name" : "AUTH0_MANAGEMENT_CLIENT_SECRET",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:auth0ManagementClientSecret::"
    },
    {
      "name" : "AUTH0_AUDIENCE",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:auth0Audience::"
    },
    {
      "name" : "USER_SERVICE_RESET_PASSWORD_TOKEN_SECRET",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:userServiceResetPasswordTokenSecret::"
    },
    {
      "name" : "AUTH0_MANAGEMENT_CLIENT_ID",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:auth0ManagementClientId::"
    },
    {
      "name" : "NOTIFY_CONTACT_ANALYST_EMAIL",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:notifyContactAnalystEmail::"
    },
    {
      "name" : "USER_SERVICE_VERIFICATION_TOKEN_SECRET",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:userServiceVerificationTokenSecret::"
    },
    {
      "name" : "AUTH0_MANAGEMENT_DOMAIN",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:auth0ManagementDomain::"
    },
    {
      "name" : "APP_SENTRY_DSN",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:appSentryDSN::"
    },
    {
      "name" : "AUTH0_JWKS_URL",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:auth0JwksUrl::"
    },
    {
      "name" : "USER_SERVICE_JWT_AUTHENTICATION_SECRET",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:userServiceJwtAuthSecret::"
    },
    {
      "name" : "AUTH0_CLIENT_CREDENTIALS_FLOW_ISSUER",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:auth0ClientCredentialsFlowIssuer::"
    },
    {
      "name" : "NOTIFIERS_WEBHOOK_UR",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:notifiersWebhookUrl::"
    },
    {
      "name" : "HASHID_SALT",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:hashSaltId::"
    },
    {
      "name" : "NOTIFY_API_KEY",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:notifyApiKey::"
    }
  ]
  healthcheck_subpath = "/"
  image_tag           = var.image_tag
  route53_domain      = local.local_r53_domain
  enable_ecs_execute  = true
}