
resource "aws_iam_role" "lambda-assume-role-email-renderer" {
  name = "iam-role-for-email-renderer-lambda"

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

module "email_renderer_lambda" {
  source               = "../../../tf-modules/lambda_in_public"
  env_name             = var.env_name
  lambda_function_name = "email-renderer-${var.env_name}"
  lambda_handler_name  = "handler.handler"
  lambda_policy_arn    = data.terraform_remote_state.stack.outputs.lambda_iam_policy_public_arn
  lambda_role_arn      = aws_iam_role.lambda-assume-role-email-renderer.arn
  lambda_role_name     = aws_iam_role.lambda-assume-role-email-renderer.name
  s3_bucket            = data.terraform_remote_state.stack.outputs.lambdas_bucket_id
  s3_key               = "email-renderer-${var.image_tag}.zip"
  runtime              = "nodejs20.x"
  lambda_memory_size   = 256

  env_vars = {}
}
