# Mail catcher for dev: captures all SMTP email instead of delivering it as addressed.
# Dev SMTP creds belong to the prod AWS account, so any real dev send draws
# on prod's shared SES daily quota (exhausted by the 2026-07-28 flood).
# UI: https://mailpit.<dev-domain> (basic auth, secret `dev-mailpit-ui-auth`).
# SMTP: mailpit.dev.internal:1025 (VPC-internal only).
# Release: a human can send one caught message onward to addresses they type in the UI.

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

# Issued in this (dev) account: dev's normal SMTP credentials are prod's and draw on prod's quota.
resource "aws_iam_user" "mailpit_relay" {
  name = "${var.env_name}-mailpit-relay-smtp"
}

resource "aws_iam_user_policy" "mailpit_relay" {
  name = "${var.env_name}-mailpit-relay-smtp"
  user = aws_iam_user.mailpit_relay.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = ["ses:SendRawEmail"],
        Effect   = "Allow",
        Resource = ["arn:aws:ses:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:identity/${local.local_r53_domain}"]
      }
    ]
  })
}

resource "aws_iam_access_key" "mailpit_relay" {
  user = aws_iam_user.mailpit_relay.name
}

resource "aws_secretsmanager_secret" "mailpit_relay_smtp" {
  name        = "${var.env_name}-mailpit-relay-smtp"
  description = "SES SMTP credentials for releasing Mailpit messages, issued in this account"
}

resource "aws_secretsmanager_secret_version" "mailpit_relay_smtp" {
  secret_id = aws_secretsmanager_secret.mailpit_relay_smtp.id
  secret_string = jsonencode({
    username = aws_iam_access_key.mailpit_relay.id
    password = aws_iam_access_key.mailpit_relay.ses_smtp_password_v4
  })
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

      # Never set MP_SMTP_RELAY_ALL or MP_SMTP_RELAY_MATCHING: they relay caught mail onward to its
      # original recipients unasked.
      environment = [
        { name = "MP_MAX_MESSAGES", value = "5000" },
        { name = "MP_SMTP_RELAY_HOST", value = "email-smtp.${data.aws_region.current.name}.amazonaws.com" },
        { name = "MP_SMTP_RELAY_PORT", value = "587" },
        { name = "MP_SMTP_RELAY_STARTTLS", value = "true" },
        { name = "MP_SMTP_RELAY_AUTH", value = "plain" },
        # SES rejects a From that is not a verified identity here; var.ses_email_from is prod's.
        { name = "MP_SMTP_RELAY_OVERRIDE_FROM", value = "mailpit@${local.local_r53_domain}" },
      ]

      secrets = [
        { name = "MP_UI_AUTH", valueFrom = aws_secretsmanager_secret.mailpit_ui_auth.arn },
        { name = "MP_SMTP_RELAY_USERNAME", valueFrom = "${aws_secretsmanager_secret.mailpit_relay_smtp.arn}:username::" },
        { name = "MP_SMTP_RELAY_PASSWORD", valueFrom = "${aws_secretsmanager_secret.mailpit_relay_smtp.arn}:password::" },
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
