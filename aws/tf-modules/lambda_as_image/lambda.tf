resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = var.lambda_role_name
  policy_arn = var.lambda_policy_arn
}

resource "aws_cloudwatch_log_group" "lambda_lg" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 14
}

resource "aws_lambda_function" "public_lambda_as_docker_image" {
  function_name = var.lambda_function_name
  architectures = ["x86_64"]
  role          = var.lambda_role_arn
  package_type  = "Image"
  image_uri     = var.ecr_image
  timeout       = var.default_timeout
  memory_size   = var.memory_size

  environment {
    variables = var.env_vars
  }

  dynamic "image_config" {
    for_each = var.image_command == null ? [] : [1]
    content {
      command = var.image_command
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_security_group_ids == null ? [] : [1]
    content {
      security_group_ids = var.vpc_security_group_ids
      subnet_ids         = var.private_subnet_ids
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_policy_attachment,
    aws_cloudwatch_log_group.lambda_lg,
  ]
}