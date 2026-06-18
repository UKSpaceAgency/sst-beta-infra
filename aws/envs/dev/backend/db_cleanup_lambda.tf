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
  default_timeout        =  900

  env_vars = {
    "SECRET_NAME"          = "${var.env_name}-backend"
    "ENV_NAME"             = var.env_name
    "vpc_endpoint_secrets" = data.terraform_remote_state.stack.outputs.vpc_secrets_manager_endpoint_arn
  }
}
