locals {
  prefix_name = "tests_ephemeris/"
}

resource "aws_iam_role" "lambda-assume-role-eph-cleanup" {
  name = "iam-role-for-vpc-eph-cleanup-lambda"

  assume_role_policy = jsonencode(
    {
      Version: "2012-10-17",
      Statement: [
        {
          Action: "sts:AssumeRole",
          Principal: {
            Service: "lambda.amazonaws.com"
          },
          Effect: "Allow",
          Sid: ""
        }
      ]
    }
  )
}

module "ephemeris_cleanup_lambda" {
  source                 = "../../tf-modules/lambda_in_vpc"
  env_name               = var.env_name
  vpc_security_group_ids = [module.network.ssh-security-group-id]
  private_subnet_ids       = module.network.private_subnet_ids
  lambda_function_name   = "ephemeris-cleanup-${var.env_name}"
  lambda_handler_name    = "main.lambda_handler"
  lambda_policy_arn      = module.iam.lambda_iam_policy_vpc_arn
  lambda_role_arn        = aws_iam_role.lambda-assume-role-eph-cleanup.arn
  lambda_role_name       = aws_iam_role.lambda-assume-role-eph-cleanup.name
  lambda_filename = "../../ephemeris-cleanup/python-package.zip"

  env_vars = {
        "SLACK_LAMBDA_ARN"  = module.alarm_lambda_slack.public_lambda_arn
        "SECRET_NAME" = "${var.env_name}-backend"
        "ENV_NAME" = var.env_name
        "vpc_endpoint_lambda" = module.network.vpc_lambda_endpoint_arn
        "vpc_endpoint_secrets" = module.network.vpc_secrets_manager_endpoint_arn
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "expiration_rule" {
  bucket = module.s3.bucket_id

  rule {
    id = "EphemerisCleanupRule"

    filter {
      prefix = local.prefix_name
    }

    expiration {
      days = 1
    }
    status = "Enabled"
  }
}

resource "aws_lambda_permission" "allow_bucket_to_lambda" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.ephemeris_cleanup_lambda.vpc_lambda_name
  principal     = "s3.amazonaws.com"
  source_arn    = module.s3.bucket_arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = module.s3.bucket_id

  lambda_function {
    lambda_function_arn = module.ephemeris_cleanup_lambda.vpc_lambda_arn
    events              = ["s3:ObjectRemoved:*"]
    filter_prefix       = local.prefix_name
  }
}