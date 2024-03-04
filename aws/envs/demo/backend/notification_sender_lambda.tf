
resource "aws_iam_role" "lambda-assume-role-notifications-sender" {
  name = "iam-role-for-notification-sender-lambda"

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

module "notifications_sender_lambda" {
  source                 = "../../../tf-modules/lambda_in_public"
  env_name               = var.env_name
  lambda_function_name   = "notification-sender-${var.env_name}"
  lambda_handler_name    = "main.lambda_handler"
  lambda_policy_arn      = data.terraform_remote_state.stack.outputs.lambda_iam_policy_public_arn
  lambda_role_arn        = aws_iam_role.lambda-assume-role-notifications-sender.arn
  lambda_role_name       = aws_iam_role.lambda-assume-role-notifications-sender.name
  s3_bucket              = data.terraform_remote_state.stack.outputs.lambdas_bucket_id
  s3_key                 = "notifications-sender-${var.image_tag}.zip"

  env_vars = {
    "ENVIRONMENT_NAME"             = upper(var.env_name)
  }
}