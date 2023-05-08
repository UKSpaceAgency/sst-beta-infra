module "backend" {
  source   = "../../../tf-modules/ecsapp"
  env_name = var.env_name
  alb_name = data.terraform_remote_state.stack.outputs.alb_name
  app_alb_priority = 10
  app_cpu = 512
  app_instances_num = 1
  app_mem = 1024
  app_name = var.app_name
  ecr_app_name = "backend"
  app_port_num = 8080
  awslogs_group = data.terraform_remote_state.stack.outputs.cluster_log_group_name
  custom_vpc_id = data.terraform_remote_state.stack.outputs.custom_vpc_id
  default_sg_id = data.terraform_remote_state.stack.outputs.default_sg_id
  ecs_cluster_arn = data.terraform_remote_state.stack.outputs.cluster_arn
  ecs_execution_role_arn = data.terraform_remote_state.stack.outputs.ecs_execution_role_arn
  ecs_task_role_arn = data.terraform_remote_state.stack.outputs.ecs_task_role_arn
  public_subnet_ids = data.terraform_remote_state.stack.outputs.public_subnet_ids
  env_vars = [
    { "name" : "APP_NAME", "value" : "API Backend (${var.image_tag})" },
    { "name" : "APP_ENV", "value" : var.env_name },
  ]
  secret_env_vars = [
    {
      "name": "DATABASE_URL",
      "valueFrom": "${data.aws_secretsmanager_secret.by-name.arn}:databaseUrl::"
    }
  ]
  healthcheck_subpath = "/"
  image_tag = "latest"
  route53_domain = var.route53_domain
  enable_ecs_execute = false

}