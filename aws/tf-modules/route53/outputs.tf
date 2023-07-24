output "main_cert_arn" {
  value = aws_acm_certificate.api_cert.arn
}

output "primary_zone_id" {
  value = aws_route53_zone.primary.zone_id
}