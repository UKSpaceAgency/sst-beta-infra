# Mail catcher for dev: captures all SMTP email instead of delivering it.
# Dev SMTP creds belong to the prod AWS account, so any real dev send draws
# on prod's shared SES daily quota (exhausted by the 2026-07-28 flood).
# UI: https://mailpit.<dev-domain> (basic auth, secret `dev-mailpit-ui-auth`).
# SMTP: mailpit.dev.internal:1025 (VPC-internal only).

resource "random_password" "mailpit_ui" {
  length  = 24
  special = false
}

resource "aws_secretsmanager_secret" "mailpit_ui_auth" {
  name        = "${var.env_name}-mailpit-ui-auth"
  description = "Basic auth (user:password) for the Mailpit web UI"
}

resource "aws_secretsmanager_secret_version" "mailpit_ui_auth" {
  secret_id     = aws_secretsmanager_secret.mailpit_ui_auth.id
  secret_string = "mailpit:${random_password.mailpit_ui.result}"
}

resource "aws_service_discovery_private_dns_namespace" "internal" {
  name = "${var.env_name}.internal"
  vpc  = data.terraform_remote_state.stack.outputs.custom_vpc_id
}

resource "aws_service_discovery_service" "mailpit" {
  name = "mailpit"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.internal.id
    dns_records {
      type = "A"
      ttl  = 10
    }
    routing_policy = "MULTIVALUE"
  }
}

resource "aws_ecs_task_definition" "mailpit" {
  family                   = "mailpit"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = data.terraform_remote_state.stack.outputs.ecs_execution_role_arn

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  network_mode = "awsvpc"

  cpu    = 256
  memory = 512

  container_definitions = jsonencode([
    {
      name      = "mailpit"
      image     = "axllent/mailpit:v1.30.6"
      essential = true
      # Advertise and accept any SMTP AUTH over plaintext: redmail always logs
      # in, and the catcher is only reachable from inside the VPC.
      command = ["--smtp-auth-accept-any", "--smtp-auth-allow-insecure"]
      portMappings = [
        {
          containerPort = 8025
          hostPort      = 8025
        },
        {
          containerPort = 1025
          hostPort      = 1025
        }
      ]

      environment = [
        { name = "MP_MAX_MESSAGES", value = "5000" }
      ]

      secrets = [
        { name = "MP_UI_AUTH", valueFrom = aws_secretsmanager_secret.mailpit_ui_auth.arn }
      ]

      logConfiguration = {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : data.terraform_remote_state.stack.outputs.cluster_log_group_name,
          "awslogs-region" : data.aws_region.current.name,
          "awslogs-stream-prefix" : "mailpit"
        }
      }
      healthCheck = {
        "command" : ["CMD", "/mailpit", "readyz"],
        "interval" : 15,
        "timeout" : 5,
        "retries" : 10,
        "startPeriod" : 20
      }
    }
  ])
}

resource "aws_lb_target_group" "mailpit_ui" {
  name                 = "mailpit-${var.env_name}-tg"
  port                 = 8025
  protocol             = "HTTP"
  protocol_version     = "HTTP1"
  target_type          = "ip"
  vpc_id               = data.terraform_remote_state.stack.outputs.custom_vpc_id
  deregistration_delay = 30

  health_check {
    # /readyz is exempt from MP_UI_AUTH basic auth
    path                = "/readyz"
    interval            = 20
    unhealthy_threshold = 5
    timeout             = 5
    healthy_threshold   = 3
    protocol            = "HTTP"
  }
}

data "aws_lb_listener" "selected443" {
  load_balancer_arn = data.aws_lb.selected.arn
  port              = 443
}

resource "aws_lb_listener_rule" "mailpit_ui" {
  listener_arn = data.aws_lb_listener.selected443.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mailpit_ui.arn
  }

  condition {
    host_header {
      values = ["mailpit.${local.local_r53_domain}"]
    }
  }
}

resource "aws_ecs_service" "mailpit" {
  name            = "mailpit"
  cluster         = data.terraform_remote_state.stack.outputs.cluster_arn
  task_definition = aws_ecs_task_definition.mailpit.arn

  # Spot interruption wipes the in-container mailbox; acceptable, it self-refills
  # and the rolling 5k cap makes it ephemeral anyway.
  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }

  desired_count         = 1
  wait_for_steady_state = true

  network_configuration {
    subnets          = data.terraform_remote_state.stack.outputs.public_subnet_ids
    security_groups  = [data.terraform_remote_state.stack.outputs.default_sg_id]
    assign_public_ip = true
  }

  load_balancer {
    container_name   = "mailpit"
    container_port   = 8025
    target_group_arn = aws_lb_target_group.mailpit_ui.arn
  }

  service_registries {
    registry_arn = aws_service_discovery_service.mailpit.arn
  }
}
