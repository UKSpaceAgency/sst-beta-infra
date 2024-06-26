data "aws_route53_zone" "primary_mys2msh" {
  name = var.mys_route53_domain
  private_zone = false
}

resource "aws_acm_certificate" "cf_cert_mys2msh" {
  provider                  = aws.useast1
  domain_name               = "*.${var.mys_route53_domain}"
  subject_alternative_names = [var.mys_route53_domain]
  validation_method         = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "r_cf_mys2msh" {
  for_each = {
    for dvo in aws_acm_certificate.cf_cert_mys2msh.domain_validation_options : dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.primary_mys2msh.zone_id
}

resource "aws_acm_certificate_validation" "api_cert_validation_mys2msh" {
  provider                = aws.useast1
  certificate_arn         = aws_acm_certificate.cf_cert_mys2msh.arn
  validation_record_fqdns = [for record in aws_route53_record.r_cf_mys2msh : record.fqdn]
}

module "www-redirect_mys2msh" {
  source                 = "../../tf-modules/www_redirect_mys2msh"
  env_name               = var.env_name
  primary_hosted_zone_id = data.aws_route53_zone.primary_mys2msh.zone_id
  us_east_1_cert_arn     = aws_acm_certificate.cf_cert_mys2msh.arn
  route53_domain         = var.mys_route53_domain
}