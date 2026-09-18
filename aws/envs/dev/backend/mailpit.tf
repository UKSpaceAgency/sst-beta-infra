# Mail catcher for dev: captures all SMTP email instead of delivering it as addressed.
# Dev SMTP creds belong to the prod AWS account, so any real dev send draws
# on prod's shared SES daily quota (exhausted by the 2026-07-28 flood).
# UI: https://mailpit.<dev-domain> (basic auth, secret `dev-mailpit-ui-auth`).
# SMTP: mailpit.dev.internal:1025 (VPC-internal only).
# Release: a human can send one caught message onward from the UI, to allowed addresses only.

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

# A dedicated SES identity for releasing, issued in this (dev) account, so released
# mail can never draw on prod's shared SES quota.
# Only the sender is rewritten: recipients of a released message still see the real end
# user's address in To/Cc and the full notification body.
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

locals {
  # Nothing releases unless this is true, and it is the ONLY condition either list below tests.
  # A second, separately written condition is how a relay host ends up configured with no allowlist
  # in force, which is release to any address on earth: an allowlist binds only when it is non-empty.
  # The exposure that makes that worth guarding: the Mailpit UI is published on the PUBLIC ALB behind
  # one shared basic-auth password, unlike the SMTP port above, which is reachable only in the VPC.
  mailpit_release_enabled = length(var.mailpit_release_allowed_recipients) > 0

  # Mailpit checks this allowlist with MatchString, which matches anywhere in the address, so the
  # anchors are what stop `alice@example.com` from also authorising `alice@example.com.evil.net`.
  # Every metacharacter is escaped, so a dot stays a dot and a plus addressed recipient survives;
  # it also means an entry cannot contribute regex structure of its own.
  #
  # Each letter becomes a two-character class, `k` to `[kK]`, because nothing on either side
  # lowercases anything: an entry written `Alice@Example.com` would otherwise never match a human
  # typing `alice@example.com`, nor the reverse, and it would fail closed and silently.
  #
  # This is deliberately NOT the `(?i)` flag, which looks equivalent and is not. Go applies UNICODE
  # simple case folding under `(?i)`, so `(?i)k` also matches U+212A KELVIN SIGN and `(?i)s` also
  # matches U+017F LONG S. The Release handler parses whatever a human types with mail.ParseAddress,
  # which accepts non-ASCII, so `(?i)` would admit byte sequences that are not the address anyone put
  # on the list. These classes admit ASCII case variants and nothing else.
  mailpit_release_allowlist = "^(${join("|", [for r in var.mailpit_release_allowed_recipients : join("", [for c in split("", r) : lower(c) == upper(c) ? replace(c, "/[.+*?()\\[\\]{}^$|\\\\]/", "\\$${0}") : "[${lower(c)}${upper(c)}]"])])})$"

  # An empty recipient list leaves MP_SMTP_RELAY_HOST unset, which is how Mailpit decides relaying
  # is off (validateRelayConfig returns early on an empty host and never sets ReleaseEnabled), so
  # the UI offers no Release button at all.
  #
  # MP_SMTP_RELAY_ALL and MP_SMTP_RELAY_MATCHING must never be set here. They are the two settings
  # that make autoRelayMessage send caught mail onward to its ORIGINAL recipients without anyone
  # asking, which is the hole this catcher exists to close. Nothing else in this file mentions
  # them, so their absence is silent, which is why it is written down.
  mailpit_relay_env = local.mailpit_release_enabled ? [
    { name = "MP_SMTP_RELAY_HOST", value = "email-smtp.${data.aws_region.current.name}.amazonaws.com" },
    { name = "MP_SMTP_RELAY_PORT", value = "587" },
    { name = "MP_SMTP_RELAY_STARTTLS", value = "true" },
    { name = "MP_SMTP_RELAY_AUTH", value = "plain" },
    { name = "MP_SMTP_RELAY_ALLOWED_RECIPIENTS", value = local.mailpit_release_allowlist },
    # SES rejects a send whose From, Sender or Return-Path is not a verified identity of the
    # sending account, and var.ses_email_from sits on the prod-account domain. Applied by
    # smtpd.Relay, which the release handler calls, so it rewrites the From header and the
    # envelope sender together. The stored message keeps the original From.
    { name = "MP_SMTP_RELAY_OVERRIDE_FROM", value = "mailpit@${local.local_r53_domain}" },
  ] : []

  mailpit_relay_secrets = local.mailpit_release_enabled ? [
    { name = "MP_SMTP_RELAY_USERNAME", valueFrom = "${aws_secretsmanager_secret.mailpit_relay_smtp.arn}:username::" },
    { name = "MP_SMTP_RELAY_PASSWORD", valueFrom = "${aws_secretsmanager_secret.mailpit_relay_smtp.arn}:password::" },
  ] : []
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
      ], local.mailpit_relay_env)

      secrets = concat([
        { name = "MP_UI_AUTH", valueFrom = aws_secretsmanager_secret.mailpit_ui_auth.arn }
      ], local.mailpit_relay_secrets)

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
