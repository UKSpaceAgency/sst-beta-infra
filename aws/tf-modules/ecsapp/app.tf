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
      portMappings = [
        {
          name = var.ecr_app_name
          containerPort = var.app_port_num
          hostPort      = var.app_port_num
        }
      ]

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
      healthCheck = {
        "command" : [
          "CMD-SHELL",
          "curl -f http://127.0.0.1:${var.app_port_num}${var.healthcheck_subpath} || exit 1"
        ],
        "interval" : 15,
        "timeout" : 5,
        "retries" : 10,
        "startPeriod" : 20
      }
    },

  ])

}


resource "random_uuid" "some_uuid" {}

resource "aws_lb_target_group" "app-tg" {
  name        = substr(format("%s-%s", "${var.app_name}-${var.env_name}-tg", replace(random_uuid.some_uuid.result, "-", "")), 0, 32)
  port        = var.app_port_num
  protocol    = "HTTP"
  protocol_version = "HTTP1"
  target_type = "ip"
  vpc_id      = var.custom_vpc_id
  deregistration_delay = 30

  health_check {
    path                = var.healthcheck_subpath
    interval            = 20
    unhealthy_threshold = 5
    timeout = 5
    healthy_threshold = 3
    protocol = "HTTP"
  }


  lifecycle {
    create_before_destroy = true
  }

}

data "aws_lb" "selected" {
  name = var.alb_name
}

data "aws_lb_listener" "selected443" {
  load_balancer_arn = data.aws_lb.selected.arn
  port              = 443
}

resource "aws_lb_listener_rule" "host_based_weighted_routing" {
  listener_arn = data.aws_lb_listener.selected443.arn
  priority     = var.app_alb_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app-tg.arn
  }

  condition {
    host_header {
      values = ["${var.app_name}.${var.route53_domain}"]
    }
  }
}




resource "aws_ecs_service" "ecs-app" {
  name                  = var.app_name
  cluster               = var.ecs_cluster_arn
  task_definition       = aws_ecs_task_definition.app_service.arn
  launch_type           = "FARGATE"
  desired_count         = var.app_instances_num
  wait_for_steady_state = true
  enable_execute_command = var.enable_ecs_execute

  service_connect_configuration {
    enabled = true
    service {
      port_name = var.ecr_app_name
      client_alias {
        port = var.app_port_num
      }
    }
  }


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

  load_balancer {
    container_name   = var.app_name
    container_port   = var.app_port_num
    target_group_arn = aws_lb_target_group.app-tg.arn
  }

}

data "aws_route53_zone" "selected" {
  name         = "${var.route53_domain}."
  private_zone = false
}

resource "aws_route53_record" "app_record_a" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${var.app_name}.${var.route53_domain}"
  type    = "A"

  alias {
    name                   = data.aws_lb.selected.dns_name
    zone_id                = data.aws_lb.selected.zone_id
    evaluate_target_health = false
  }
}

locals {
  current_datetime = formatdate("YYYY-MM-DD_HH_mm_ss", timestamp())
  current_datetime_pretty = formatdate("YYYY-MM-DD HH:mm:ss", timestamp())
}

//create deployment marker in deployments history bucket
resource "aws_s3_object" "deployment_file" {
  bucket = var.deployment_hist_bucket_id
  key    = "${local.current_datetime}.txt"
  content = "${local.current_datetime_pretty}\n${var.image_tag}\n${var.env_name}-${var.app_name}"
  content_type = "text/plain"
}