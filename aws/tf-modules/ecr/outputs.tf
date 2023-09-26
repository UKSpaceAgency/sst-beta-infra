output "frontend_ecr_arn" {
  value = aws_ecr_repository.frontend.arn
}

output "backend_ecr_arn" {
  value = aws_ecr_repository.backend.arn
}