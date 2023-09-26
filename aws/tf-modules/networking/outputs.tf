output "pg-security-group-id" {
  value = aws_security_group.pg-service.id
}

output "ssh-security-group-id" {
  value = aws_security_group.allow_ssh.id
}

output "allow_tls_only_sg_id" {
  value = aws_security_group.allow_tls.id
}

output "default_sg_id" {
  value = data.aws_security_group.default.id
}

output "private_subnet_ids" {
  value = aws_subnet.private.*.id
}

output "public_subnet_ids" {
  value = aws_subnet.public.*.id
}

output "custom_vpc_id" {
  value = aws_vpc.custom_vpc.id
}

output "vpc_lambda_endpoint_arn" {
  value = aws_vpc_endpoint.lambda_endpoint.arn
}

output "vpc_secrets_manager_endpoint_arn" {
  value = aws_vpc_endpoint.secrets_manager_endpoint.arn
}