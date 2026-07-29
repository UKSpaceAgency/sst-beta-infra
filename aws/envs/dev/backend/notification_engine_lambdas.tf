resource "aws_iam_role" "notification_engine_lambda" {
  name = "iam-role-notification-engine-lambda-${var.env_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Principal = { Service = "lambda.amazonaws.com" },
        Effect    = "Allow",
        Sid       = ""
      }
    ]
  })
}

resource "aws_iam_policy" "notification_engine_lambda" {
  name = "iam-policy-notification-engine-lambda-${var.env_name}"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"],
        Effect = "Allow",
        Resource = [
          aws_sqs_queue.notification_engine_events.arn,
          aws_sqs_queue.notification_engine_delivery.arn,
        ]
      },
      {
        Action   = ["sqs:SendMessage"],
        Effect   = "Allow",
        Resource = [aws_sqs_queue.notification_engine_delivery.arn]
      },
      {
        Action   = ["secretsmanager:GetSecretValue"],
        Effect   = "Allow",
        Resource = [data.aws_secretsmanager_secret.by-name.arn]
      },
      {
        Action   = ["lambda:InvokeFunction"],
        Effect   = "Allow",
        Resource = [module.email_renderer_lambda.public_lambda_arn]
      },
      {
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# lambda_as_image only wires one policy_arn per instance, so the VPC ENI policy
# (shared with db_cleanup/eph_cleanup) is attached separately to the shared role.
resource "aws_iam_role_policy_attachment" "notification_engine_lambda_vpc" {
  role       = aws_iam_role.notification_engine_lambda.name
  policy_arn = data.terraform_remote_state.stack.outputs.lambda_iam_policy_vpc_arn
}

locals {
  notification_engine_image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.id}.amazonaws.com/notification-engine:${var.image_tag}"
  notification_engine_env = {
    "SECRET_NAME"                            = "${var.env_name}-backend"
    "NOTIFICATION_ENGINE_ENABLED"            = "True"
    "NOTIFICATION_ENGINE_EVENTS_QUEUE_URL"   = aws_sqs_queue.notification_engine_events.url
    "NOTIFICATION_ENGINE_DELIVERY_QUEUE_URL" = aws_sqs_queue.notification_engine_delivery.url
    "APP_EMAIL_RENDERER_LAMBDA_NAME"         = module.email_renderer_lambda.public_lambda_name
    "APP_ENVIRONMENT"                        = var.env_name
    "DATABASE_POOL_MIN_SIZE"                 = "1"
    "DATABASE_POOL_MAX_SIZE"                 = "1"
    "APP_SES_SMTP_HOST"                      = "${aws_service_discovery_service.mailpit.name}.${aws_service_discovery_private_dns_namespace.internal.name}"
    "APP_SES_SMTP_PORT"                      = "1025"
    "APP_SES_SMTP_USE_SSL"                   = "False"
  }
}

module "notification_engine_evaluator_lambda" {
  source                 = "../../../tf-modules/lambda_as_image"
  env_name               = var.env_name
  lambda_function_name   = "notification-engine-evaluator-${var.env_name}"
  lambda_policy_arn      = aws_iam_policy.notification_engine_lambda.arn
  lambda_role_arn        = aws_iam_role.notification_engine_lambda.arn
  lambda_role_name       = aws_iam_role.notification_engine_lambda.name
  ecr_image              = local.notification_engine_image
  image_command          = ["app.notification_engine.handlers.evaluator_handler"]
  vpc_security_group_ids = [data.terraform_remote_state.stack.outputs.default_sg_id]
  private_subnet_ids     = data.terraform_remote_state.stack.outputs.private_subnet_ids
  default_timeout        = 150
  memory_size            = 1024
  env_vars               = local.notification_engine_env

  depends_on = [aws_iam_role_policy_attachment.notification_engine_lambda_vpc]
}

module "notification_engine_sender_lambda" {
  source                 = "../../../tf-modules/lambda_as_image"
  env_name               = var.env_name
  lambda_function_name   = "notification-engine-sender-${var.env_name}"
  lambda_policy_arn      = aws_iam_policy.notification_engine_lambda.arn
  lambda_role_arn        = aws_iam_role.notification_engine_lambda.arn
  lambda_role_name       = aws_iam_role.notification_engine_lambda.name
  ecr_image              = local.notification_engine_image
  image_command          = ["app.notification_engine.handlers.sender_handler"]
  vpc_security_group_ids = [data.terraform_remote_state.stack.outputs.default_sg_id]
  private_subnet_ids     = data.terraform_remote_state.stack.outputs.private_subnet_ids
  default_timeout        = 150
  memory_size            = 1024
  env_vars               = local.notification_engine_env

  depends_on = [aws_iam_role_policy_attachment.notification_engine_lambda_vpc]
}

module "notification_engine_flusher_lambda" {
  source                 = "../../../tf-modules/lambda_as_image"
  env_name               = var.env_name
  lambda_function_name   = "notification-engine-flusher-${var.env_name}"
  lambda_policy_arn      = aws_iam_policy.notification_engine_lambda.arn
  lambda_role_arn        = aws_iam_role.notification_engine_lambda.arn
  lambda_role_name       = aws_iam_role.notification_engine_lambda.name
  ecr_image              = local.notification_engine_image
  image_command          = ["app.notification_engine.handlers.flusher_handler"]
  vpc_security_group_ids = [data.terraform_remote_state.stack.outputs.default_sg_id]
  private_subnet_ids     = data.terraform_remote_state.stack.outputs.private_subnet_ids
  default_timeout        = 150
  memory_size            = 1024
  env_vars               = local.notification_engine_env

  depends_on = [aws_iam_role_policy_attachment.notification_engine_lambda_vpc]
}

resource "aws_lambda_event_source_mapping" "notification_engine_events" {
  event_source_arn        = aws_sqs_queue.notification_engine_events.arn
  function_name           = module.notification_engine_evaluator_lambda.public_lambda_arn
  batch_size              = 10
  function_response_types = ["ReportBatchItemFailures"]

  # Bounds concurrent lambda pools so the shared RDS connection limit survives an event burst.
  scaling_config {
    maximum_concurrency = 5
  }
}

resource "aws_lambda_event_source_mapping" "notification_engine_delivery" {
  event_source_arn        = aws_sqs_queue.notification_engine_delivery.arn
  function_name           = module.notification_engine_sender_lambda.public_lambda_arn
  batch_size              = 10
  function_response_types = ["ReportBatchItemFailures"]

  # Paused: dev SMTP creds draw on the prod account's shared SES daily quota.
  # Re-enable once dev sends to the in-VPC mail catcher.
  enabled = false

  # Also throttles outbound email rate to the shared test inbox.
  scaling_config {
    maximum_concurrency = 2
  }
}

resource "aws_cloudwatch_event_rule" "notification_engine_flusher" {
  name                = "notification-engine-flusher-${var.env_name}"
  description         = "Flush due notification digest windows"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "notification_engine_flusher" {
  rule = aws_cloudwatch_event_rule.notification_engine_flusher.name
  arn  = module.notification_engine_flusher_lambda.public_lambda_arn
}

resource "aws_lambda_permission" "allow_events_to_invoke_flusher" {
  statement_id  = "AllowExecutionFromCloudWatchEvents"
  action        = "lambda:InvokeFunction"
  function_name = module.notification_engine_flusher_lambda.vpc_lambda_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.notification_engine_flusher.arn
}
