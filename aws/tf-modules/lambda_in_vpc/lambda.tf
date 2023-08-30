resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = var.lambda_role_name
  policy_arn = var.lambda_policy_arn
}

resource "aws_cloudwatch_log_group" "lambda_lg" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 14
}

resource "aws_lambda_function" "vpc_lambda" {
  function_name = var.lambda_function_name
  architectures = ["x86_64"]
  role          = var.lambda_role_arn
  handler       = var.lambda_handler_name
  filename = var.lambda_filename
  source_code_hash = filebase64sha256(var.lambda_filename)
  runtime = "python3.11"
  timeout = 30 //seconds

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