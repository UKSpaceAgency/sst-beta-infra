# Mail catcher for dev: captures all SMTP email instead of delivering it as addressed.
# Dev SMTP creds belong to the prod AWS account, so any real dev send draws
# on prod's shared SES daily quota (exhausted by the 2026-07-28 flood).
# UI: https://mailpit.<dev-domain> (basic auth, secret `dev-mailpit-ui-auth`).
# SMTP: mailpit.dev.internal:1025 (VPC-internal only).
# When var.mailpit_forward_recipients is non-empty, a copy of each message also goes to
# those addresses and only those, via this account's own SES. See the block below.

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

# Forwarding a copy of caught mail out to var.mailpit_forward_recipients. Two properties
# keep the catcher's guarantee intact: the copy is re-addressed to that list, so the
# original recipients are never reachable, and it is sent by this (dev) account's own SES
# identity, so the prod quota the 2026-07-28 flood exhausted is out of reach from here.
# Mailpit keeps the untouched original either way, so the UI stays the source of truth.
resource "aws_iam_user" "mailpit_forward" {
  name = "${var.env_name}-mailpit-forward-smtp"
}

resource "aws_iam_user_policy" "mailpit_forward" {
  name = "${var.env_name}-mailpit-forward-smtp"
  user = aws_iam_user.mailpit_forward.name

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

resource "aws_iam_access_key" "mailpit_forward" {
  user = aws_iam_user.mailpit_forward.name
}

resource "aws_secretsmanager_secret" "mailpit_forward_smtp" {
  name        = "${var.env_name}-mailpit-forward-smtp"
  description = "SES SMTP credentials for the Mailpit forwarder, issued in this account"
}

resource "aws_secretsmanager_secret_version" "mailpit_forward_smtp" {
  secret_id = aws_secretsmanager_secret.mailpit_forward_smtp.id
  secret_string = jsonencode({
    username = aws_iam_access_key.mailpit_forward.id
    password = aws_iam_access_key.mailpit_forward.ses_smtp_password_v4
  })
}

locals {
  # An empty recipient list leaves MP_SMTP_FORWARD_HOST unset, which is how Mailpit
  # decides forwarding is off (validateForwardConfig returns early on an empty host).
  # Setting the host without a To list is a startup error, so the two move together.
  mailpit_forward_env = length(var.mailpit_forward_recipients) == 0 ? [] : [
    { name = "MP_SMTP_FORWARD_TO", value = join(",", var.mailpit_forward_recipients) },
    { name = "MP_SMTP_FORWARD_HOST", value = "email-smtp.${data.aws_region.current.name}.amazonaws.com" },
    { name = "MP_SMTP_FORWARD_PORT", value = "587" },
    { name = "MP_SMTP_FORWARD_STARTTLS", value = "true" },
    { name = "MP_SMTP_FORWARD_AUTH", value = "plain" },
    # SES only accepts a From on a verified identity of the sending account, and
    # var.ses_email_from sits on the prod-account domain. The stored copy keeps the
    # original From, so only the forwarded copy is rewritten.
    { name = "MP_SMTP_FORWARD_OVERRIDE_FROM", value = "mailpit@${local.local_r53_domain}" },
    { name = "MP_SMTP_FORWARD_RETURN_PATH", value = "mailpit@${local.local_r53_domain}" },
  ]

  mailpit_forward_secrets = length(var.mailpit_forward_recipients) == 0 ? [] : [
    { name = "MP_SMTP_FORWARD_USERNAME", valueFrom = "${aws_secretsmanager_secret.mailpit_forward_smtp.arn}:username::" },
    { name = "MP_SMTP_FORWARD_PASSWORD", valueFrom = "${aws_secretsmanager_secret.mailpit_forward_smtp.arn}:password::" },
  ]
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

      environment = concat([
        { name = "MP_MAX_MESSAGES", value = "5000" }
      ], local.mailpit_forward_env)

      secrets = concat([
        { name = "MP_UI_AUTH", valueFrom = aws_secretsmanager_secret.mailpit_ui_auth.arn }
      ], local.mailpit_forward_secrets)

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
