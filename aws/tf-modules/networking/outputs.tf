output "pg-security-group-id" {
  value = aws_security_group.pg-service.id
}

output "ssh-security-group-id" {
  value = aws_security_group.allow_ssh.id
}

output "private_subnet_ids" {
  value = aws_subnet.private.*.id
}

output "public_subnet_ids" {
  value = aws_subnet.public.*.id
}