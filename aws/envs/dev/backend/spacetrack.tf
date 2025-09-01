module "spacetrack_worker" {
  source                 = "../../../tf-modules/workerapp"
  env_name               = var.env_name
  app_cpu                = 1024
  app_instances_num      = 1
  app_mem                = 2048
  app_name               = "spacetrack"
  ecr_app_name           = "backend"
  default_capacity_provider = "FARGATE_SPOT"
  cron_expression        = lookup(local.ingestion_schedule, lower("spacetrack"), "0 0 31 2 *")
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
  worker_command         = ["poetry", "run", "python", "-m", "app.periodics.space_track_worker", "--cron"]
  env_vars = [
    { "name" : "APP_NAME", "value" : "Spacetrack worker (${var.image_tag})" },
    { "name" : "APP_ENVIRONMENT", "value" : var.env_name },
    { "name" : "APP_SENTRY_SAMPLE_RATE", "value" : "0.05" },
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
    }
  ]

}