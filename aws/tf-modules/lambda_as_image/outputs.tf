output "public_lambda_arn" {
  value = aws_lambda_function.public_lambda_as_docker_image.arn
}

output "vpc_lambda_name" {
  value = aws_lambda_function.public_lambda_as_docker_image.function_name
}
