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
  timeout       = 300 //seconds
  memory_size   = 2048 //megs

  environment {
    variables = var.env_vars
  }


  depends_on = [
    aws_iam_role_policy_attachment.lambda_policy_attachment,
    aws_cloudwatch_log_group.lambda_lg,
  ]
}