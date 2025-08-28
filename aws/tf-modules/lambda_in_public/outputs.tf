output "public_lambda_arn" {
  value = aws_lambda_function.public_lambda.arn
}

output "public_lambda_name" {
  value = aws_lambda_function.public_lambda.function_name
}

