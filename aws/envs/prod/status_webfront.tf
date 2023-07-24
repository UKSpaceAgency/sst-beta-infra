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


resource "aws_cloudfront_distribution" "stats_pingdom" {
  origin {
    domain_name = "secure-stats.pingdom.com"
    origin_id   = "secure-stats.pingdom.com"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods = [
      "HEAD",
      "GET",
      "OPTIONS"
    ]
    cached_methods = [
      "HEAD",
      "GET",
      "OPTIONS"
    ]
    target_origin_id         = "secure-stats.pingdom.com"
    viewer_protocol_policy   = "redirect-to-https"
    cache_policy_id          = data.aws_cloudfront_cache_policy.managed-caching-disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.managed-all-viewer.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cf_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  aliases             = ["status.${var.route53_domain}"]
  default_root_object = "8bo5s7mggryk"
  price_class         = "PriceClass_100"
  enabled             = true
  is_ipv6_enabled     = true
  http_version        = "http2"
  wait_for_deployment = false

}


resource "aws_route53_record" "environment_itself" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "status.${var.route53_domain}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.stats_pingdom.domain_name
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}
