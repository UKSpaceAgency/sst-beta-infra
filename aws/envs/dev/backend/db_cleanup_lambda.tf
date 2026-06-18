resource "aws_iam_role" "lambda-assume-role-db-cleanup" {
  name = "iam-role-for-vpc-db-cleanup-lambda"

  assume_role_policy = jsonencode(
    {
      Version : "2012-10-17",
      Statement : [
        {
          Action : "sts:AssumeRole",
          Principal : {
            Service : "lambda.amazonaws.com"
          },
          Effect : "Allow",
          Sid : ""
        }
      ]
    }
  )
}

module "db_cleanup_lambda" {
  source                 = "../../../tf-modules/lambda_in_vpc"
  env_name               = var.env_name
  vpc_security_group_ids = [data.terraform_remote_state.stack.outputs.default_sg_id]
  private_subnet_ids     = data.terraform_remote_state.stack.outputs.private_subnet_ids
  lambda_function_name   = "db-cleanup-${var.env_name}"
  lambda_handler_name    = "main.lambda_handler"
  lambda_policy_arn      = data.terraform_remote_state.stack.outputs.lambda_iam_policy_vpc_arn
  lambda_role_arn        = aws_iam_role.lambda-assume-role-db-cleanup.arn
  lambda_role_name       = aws_iam_role.lambda-assume-role-db-cleanup.name
  s3_bucket              = data.terraform_remote_state.stack.outputs.lambdas_bucket_id
  s3_key                 = "db-cleanup-${var.image_tag}.zip"
  default_timeout        = 900

  env_vars = {
    "SECRET_NAME"          = "${var.env_name}-backend"
    "ENV_NAME"             = var.env_name
    "vpc_endpoint_secrets" = data.terraform_remote_state.stack.outputs.vpc_secrets_manager_endpoint_arn
  }
}

resource "aws_cloudwatch_event_rule" "db_cleanup_daily" {
  name                = "db-cleanup-daily-${var.env_name}"
  description         = "Run the DEV database cleanup Lambda every day at 18:00 UTC"
  schedule_expression = "cron(0 18 * * ? *)"
}

resource "aws_cloudwatch_event_target" "db_cleanup_lambda" {
  rule = aws_cloudwatch_event_rule.db_cleanup_daily.name
  arn  = module.db_cleanup_lambda.vpc_lambda_arn

  input = jsonencode(
    {
    "environment": "DEV",
    "tasks": [
      {
        "table_name": "events",
        "batch_size": 50000,
        "delay_seconds": 1,
        "retention_days": 365
      },
      {
        "table_name": "unique_events",
        "batch_size": 50000,
        "delay_seconds": 1,
        "retention_days": 365
      },
      {
        "table_name": "cdms",
        "batch_size": 50000,
        "delay_seconds": 1,
        "retention_days": 365
      },
      {
        "table_name": "cdm_data",
        "batch_size": 50000,
        "delay_seconds": 1,
        "retention_days": 365
      },
      {
        "table_name": "cdm_headers",
        "batch_size": 50000,
        "delay_seconds": 1,
        "retention_days": 365
      },
      {
        "table_name": "cdm_metadata",
        "batch_size": 50000,
        "delay_seconds": 1,
        "retention_days": 365
      },
      {
        "table_name": "cdm_relative_data_metadata",
        "batch_size": 50000,
        "delay_seconds": 1,
        "retention_days": 365
      },
      {
        "table_name": "analyses",
        "batch_size": 50000,
        "delay_seconds": 1,
        "retention_days": 365
      },
      {
        "table_name": "tips",
        "batch_size": 50000,
        "delay_seconds": 1,
        "retention_days": 365
      },
      {
        "table_name": "notifications",
        "batch_size": 50000,
        "delay_seconds": 1,
        "retention_days": 180
      }
    ]
  }
  )
}

resource "aws_lambda_permission" "allow_cloudwatch_events_to_invoke_db_cleanup" {
  statement_id  = "AllowExecutionFromCloudWatchEvents"
  action        = "lambda:InvokeFunction"
  function_name = module.db_cleanup_lambda.vpc_lambda_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.db_cleanup_daily.arn
}
