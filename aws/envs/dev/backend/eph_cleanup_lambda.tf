locals {
  prefix_name = "ephemeris/"
  expiration_days = 500
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
  source                 = "../../../tf-modules/lambda_in_vpc"
  env_name               = var.env_name
  vpc_security_group_ids = [data.terraform_remote_state.stack.outputs.default_sg_id]
  private_subnet_ids       = data.terraform_remote_state.stack.outputs.private_subnet_ids
  lambda_function_name   = "ephemeris-cleanup-${var.env_name}"
  lambda_handler_name    = "main.lambda_handler"
  lambda_policy_arn      = data.terraform_remote_state.stack.outputs.lambda_iam_policy_vpc_arn
  lambda_role_arn        = aws_iam_role.lambda-assume-role-eph-cleanup.arn
  lambda_role_name       = aws_iam_role.lambda-assume-role-eph-cleanup.name
  s3_bucket = data.terraform_remote_state.stack.outputs.lambdas_bucket_id
  s3_key = "ephemeris-cleanup-${var.image_tag}.zip"

  env_vars = {
        "SECRET_NAME" = "${var.env_name}-backend"
        "ENV_NAME" = var.env_name
        "vpc_endpoint_secrets" = data.terraform_remote_state.stack.outputs.vpc_secrets_manager_endpoint_arn
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "expiration_rule" {
  bucket = data.terraform_remote_state.stack.outputs.s3_bucket_id

  rule {
    id = "EphemerisCleanupRule"

    filter {
      prefix = local.prefix_name
    }

    expiration {
      days = local.expiration_days
    }
    status = "Enabled"
  }
}

resource "aws_lambda_permission" "allow_bucket_to_lambda" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.ephemeris_cleanup_lambda.vpc_lambda_name
  principal     = "s3.amazonaws.com"
  source_arn    = data.terraform_remote_state.stack.outputs.s3_bucket_arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = data.terraform_remote_state.stack.outputs.s3_bucket_id

  lambda_function {
    lambda_function_arn = module.ephemeris_cleanup_lambda.vpc_lambda_arn
    events              = ["s3:ObjectRemoved:*","s3:LifecycleExpiration:*"]
    filter_prefix       = local.prefix_name
  }
}