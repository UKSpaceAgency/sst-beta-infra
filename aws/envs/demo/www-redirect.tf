resource "aws_acm_certificate" "cf_cert" {
  provider                  = aws.useast1
  domain_name               = "*.${var.route53_domain}"
  subject_alternative_names = [var.route53_domain]
  validation_method         = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "r_cf" {
  for_each = {
    for dvo in aws_acm_certificate.cf_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = module.route53.primary_zone_id
}

resource "aws_acm_certificate_validation" "api_cert_validation" {
  provider                = aws.useast1
  certificate_arn         = aws_acm_certificate.cf_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.r_cf : record.fqdn]
}

module "www-redirect" {
  source     = "../../tf-modules/www_redirect"
  env_name   = var.env_name
  primary_hosted_zone_id = module.route53.primary_zone_id
  us_east_1_cert_arn = aws_acm_certificate.cf_cert.arn
  route53_domain = var.route53_domain
  log_bucket_id = module.s3.log_bucket_id
}