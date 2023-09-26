output "vpc_lambda_arn" {
  value = aws_lambda_function.vpc_lambda.arn
}

output "vpc_lambda_name" {
  value = aws_lambda_function.vpc_lambda.function_name
}