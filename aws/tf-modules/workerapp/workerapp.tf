data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_ecr_image" "service_image" {
  repository_name = var.ecr_app_name
  image_tag       = var.image_tag
}

resource "aws_ecs_task_definition" "app_service" {
  family                   = var.app_name
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = var.ecs_task_role_arn
  execution_role_arn       = var.ecs_execution_role_arn

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  network_mode = "awsvpc"

  cpu    = var.app_cpu
  memory = var.app_mem

  tags = {
    task-family = var.app_name
    image_size_fail_pass = data.aws_ecr_image.service_image.image_size_in_bytes
  }

  container_definitions = jsonencode([
    {
      name         = var.app_name
      image        = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.id}.amazonaws.com/${var.ecr_app_name}:${data.aws_ecr_image.service_image.image_tag}"
      cpu          = var.app_cpu
      memory       = var.app_mem
      essential    = true
      command      = var.worker_command
      environment = var.env_vars
      secrets = var.secret_env_vars

      logConfiguration = {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : var.awslogs_group,
          "awslogs-region" : data.aws_region.current.name,
          "awslogs-stream-prefix" : var.ecr_app_name,
          "awslogs-datetime-format" : "%Y-%m-%d %H:%M:%S%L"
        }
      }
    },

  ])

}

resource "aws_ecs_service" "ecs-app" {
  name                  = var.app_name
  cluster               = var.ecs_cluster_arn
  task_definition       = aws_ecs_task_definition.app_service.arn
  launch_type           = "FARGATE"
  desired_count         = var.app_instances_num
  wait_for_steady_state = true
  enable_execute_command = var.enable_ecs_execute



  lifecycle {
    ignore_changes = [
      desired_count
    ]
  }

  network_configuration {
    subnets          = var.public_subnet_ids
    security_groups  = [var.default_sg_id]
    assign_public_ip = true
  }


}