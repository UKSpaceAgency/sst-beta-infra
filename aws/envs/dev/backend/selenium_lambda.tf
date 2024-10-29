data "aws_region" "current" {}

data "aws_caller_identity" "current" {}


resource "aws_iam_policy" "lambda-iam-policy-selenium" {
  name        = "iam-policy-for-selenium-lambda"
  path        = "/"
  description = "IAM policy for selenium lambda"

  policy = jsonencode(
    {
      Version : "2012-10-17",
      Statement : [
        {
          Action : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          Resource : "arn:aws:logs:*:*:*",
          Effect : "Allow"
        },
        {
          "Action": [
            "s3:*"
          ],
          "Effect": "Allow",
          "Resource": [
            data.terraform_remote_state.stack.outputs.s3_reentry_bucket_arn,
            "${data.terraform_remote_state.stack.outputs.s3_reentry_bucket_arn}/*"
          ]
        }
      ]
    }
  )
}

resource "aws_iam_role" "lambda-assume-role-selenium-lambda" {
  name = "iam-role-for-selenium-lambda"

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

data "aws_ecr_image" "service_image" {
  repository_name = "selenium-lambda"
  image_tag       = var.image_tag
}

data "aws_secretsmanager_secret" "frontend_secret" {
  name = "${var.env_name}-frontend"
}

data "aws_secretsmanager_secret_version" "frontend_secret_version" {
  secret_id = data.aws_secretsmanager_secret.frontend_secret.id
}

locals {
  secret_data = jsondecode(data.aws_secretsmanager_secret_version.frontend_secret_version.secret_string)
}

module "selenium_lambda" {
  source               = "../../../tf-modules/lambda_as_image"
  env_name             = var.env_name
  lambda_function_name = "selenium-lambda-${var.env_name}"
  lambda_policy_arn    = aws_iam_policy.lambda-iam-policy-selenium.arn
  lambda_role_arn      = aws_iam_role.lambda-assume-role-selenium-lambda.arn
  lambda_role_name     = aws_iam_role.lambda-assume-role-selenium-lambda.name
  ecr_image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.id}.amazonaws.com/${data.aws_ecr_image.service_image.repository_name}:${data.aws_ecr_image.service_image.image_tag}"

  env_vars = {
    "ENVIRONMENT_NAME" = upper(var.env_name),
    "BUCKET_NAME" = data.terraform_remote_state.stack.outputs.s3_reentry_bucket_id,
    "MAPBOX_ACCESS_TOKEN" = local.secret_data["nextPublicMapboxAccessToken"]
  }
}

resource "aws_lambda_permission" "allow_bucket_to_selenium_lambda" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.selenium_lambda.vpc_lambda_name
  principal     = "s3.amazonaws.com"
  source_arn    = data.terraform_remote_state.stack.outputs.s3_reentry_bucket_arn
}

resource "aws_s3_bucket_notification" "bucket_notification_selenium_lambda" {
 bucket = data.terraform_remote_state.stack.outputs.s3_reentry_bucket_id

 lambda_function {
   lambda_function_arn = module.selenium_lambda.public_lambda_arn
   events              = ["s3:ObjectCreated:*"]
   filter_prefix       = "reentry_event_reports/"
   filter_suffix       = ".json"
 }
}


# CloudWatch Event rule to trigger every 6 hours
resource "aws_cloudwatch_event_rule" "schedule_rule" {
  name                = "selenium_lambda_schedule_rule"
  schedule_expression = "rate(6 hours)"
}

# Event target to invoke Lambda
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.schedule_rule.name
  arn       = module.selenium_lambda.public_lambda_arn
}

# Grant CloudWatch Events permission to invoke the Lambda function
resource "aws_lambda_permission" "allow_cloudwatch_invoke" {
  statement_id  = "AllowCloudWatchEvents"
  action        = "lambda:InvokeFunction"
  function_name = module.selenium_lambda.vpc_lambda_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule_rule.arn
}