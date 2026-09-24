resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = var.lambda_role_name
  policy_arn = var.lambda_policy_arn
}

resource "aws_cloudwatch_log_group" "lambda_lg" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 14
}

data "aws_s3_object" "package" {
  bucket = var.s3_bucket
  key    = var.s3_key
}

resource "aws_lambda_function" "vpc_lambda" {
  function_name     = var.lambda_function_name
  architectures     = ["x86_64"]
  role              = var.lambda_role_arn
  handler           = var.lambda_handler_name
  s3_bucket         = var.s3_bucket
  s3_key            = var.s3_key
  s3_object_version = data.aws_s3_object.package.version_id
  runtime           = "python3.11"
  timeout           = var.default_timeout
  environment {
    variables = var.env_vars
  }

  vpc_config {
    security_group_ids = var.vpc_security_group_ids
    subnet_ids         = var.private_subnet_ids
  }


  depends_on = [
    aws_iam_role_policy_attachment.lambda_policy_attachment,
    aws_cloudwatch_log_group.lambda_lg,
  ]
}