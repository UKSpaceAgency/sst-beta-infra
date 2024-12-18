module "esadiscos_worker" {
  source                 = "../../../tf-modules/workerapp"
  env_name               = var.env_name
  app_cpu                = 1024
  app_instances_num      = 1
  app_mem                = 2048
  app_name               = "esadiscos"
  ecr_app_name           = "backend"
  default_capacity_provider = "FARGATE_SPOT"
  cron_expression        = lookup(local.ingestion_schedule, lower("esadiscos"), "0 0 31 2 *")
  awslogs_group          = data.terraform_remote_state.stack.outputs.cluster_log_group_name
  custom_vpc_id          = data.terraform_remote_state.stack.outputs.custom_vpc_id
  default_sg_id          = data.terraform_remote_state.stack.outputs.default_sg_id
  ecs_cluster_arn        = data.terraform_remote_state.stack.outputs.cluster_arn
  ecs_execution_role_arn = data.terraform_remote_state.stack.outputs.ecs_execution_role_arn
  ecs_task_role_arn      = data.terraform_remote_state.stack.outputs.ecs_task_role_arn
  ecs_events_role_arn    = data.terraform_remote_state.stack.outputs.ecs_events_role_arn
  ecs_events_role_id     = data.terraform_remote_state.stack.outputs.ecs_events_role_id
  public_subnet_ids      = data.terraform_remote_state.stack.outputs.public_subnet_ids
  image_tag              = var.image_tag
  enable_ecs_execute     = true
  worker_command         = ["poetry", "run", "python", "-m", "app.periodics.esa_discos_worker", "--cron"]
  env_vars = [
    { "name" : "APP_NAME", "value" : "Esa Discos worker (${var.image_tag})" },
    { "name" : "APP_ENVIRONMENT", "value" : var.env_name },
    { "name" : "APP_SENTRY_SAMPLE_RATE", "value" : "0.05" },
    { "name" : "ESA_DISCOS_maximum_requests_per_minute", "value" : "10" },
  ]
  secret_env_vars = [
    {
      "name" : "DATABASE_URL",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:databaseUrl::"
    },
    {
      "name" : "NOTIFY_CONTACT_ANALYST_EMAIL",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:notifyContactAnalystEmail::"
    },
    {
      "name" : "APP_SENTRY_DSN",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:appSentryDSN::"
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
    },
    {
      "name" : "ESA_DISCOS_ACCESS_TOKEN",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:esaDiscosAccessToken::"
    }
  ]

}