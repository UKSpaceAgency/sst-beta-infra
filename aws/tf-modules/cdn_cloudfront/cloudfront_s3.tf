resource "random_uuid" "some_uuid" {}

data "aws_cloudfront_response_headers_policy" "managed-cors-security" {
  name = "Managed-CORS-with-preflight-and-SecurityHeadersPolicy"
}



resource "aws_cloudfront_origin_access_control" "s3_only_access_control" {
  name                              = "orig-s3-for-cdn-msh"
  description                       = "Origin Access for cdn-bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "cdn_dist" {
  origin {
    domain_name              = var.bucket_regional_name
    origin_id                = "msh-cdn"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_only_access_control.id
  }

  origin {
    domain_name = var.alb_domain_name
    origin_id   = "msh-alb"

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "https-only"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_read_timeout      = 30
      origin_keepalive_timeout = 5
    }
  }



  default_cache_behavior {
    allowed_methods = [
      "HEAD",
      "DELETE",
      "POST",
      "GET",
      "OPTIONS",
      "PUT",
      "PATCH"
    ]
    cached_methods = [
      "HEAD",
      "GET"
    ]
    target_origin_id       = "msh-alb"
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = data.aws_cloudfront_cache_policy.managed-caching-disabled.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.managed-all-viewer.id
  }

  ordered_cache_behavior {
    allowed_methods = [
      "HEAD",
      "GET"
    ]
    cached_methods = [
      "HEAD",
      "GET"
    ]
    path_pattern           = "/reentry_event_reports/*"
    target_origin_id       = "msh-cdn"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    cache_policy_id        = data.aws_cloudfront_cache_policy.managed-caching-optimized.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.us_east_1_cert_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  aliases             = ["${var.cdn_name}.${var.route53_domain}"]
  wait_for_deployment = false
  price_class         = "PriceClass_100"
  enabled             = true
  is_ipv6_enabled     = true
  http_version        = "http2"
  comment             = "www-cdn-msh"
}


resource "aws_route53_record" "proper_name" {
  zone_id = var.primary_hosted_zone_id
  name    = "${var.cdn_name}.${var.route53_domain}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn_dist.domain_name
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "proper_name_aaaa" {
  zone_id = var.primary_hosted_zone_id
  name    = "${var.cdn_name}.${var.route53_domain}"
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.cdn_dist.domain_name
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}



resource "aws_s3_bucket_policy" "allow_public_frontend" {
  bucket = var.bucket_id
  policy = data.aws_iam_policy_document.public_frontend_policy.json
}