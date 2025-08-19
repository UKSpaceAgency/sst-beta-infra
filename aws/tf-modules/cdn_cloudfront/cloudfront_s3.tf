resource "random_uuid" "some_uuid" {}

resource "aws_s3_bucket" "cdn" {
  bucket        = substr(format("%s-%s", "cdn-msh-${var.env_name}", replace(random_uuid.some_uuid.result, "-", "")), 0, 32)
  force_destroy = true
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
    domain_name              = aws_s3_bucket.cdn.bucket_regional_domain_name
    origin_id                = "cdn-msh"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_only_access_control.id
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
    target_origin_id       = "cdn-msh"
    viewer_protocol_policy = "redirect-to-https"
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

  aliases             = ["cdn.${var.route53_domain}"]
  wait_for_deployment = false
  price_class         = "PriceClass_100"
  enabled             = true
  is_ipv6_enabled     = true
  http_version        = "http2"
  comment             = "cdn-msh"
  default_root_object = "index.html"

}


resource "aws_route53_record" "proper_name" {
  zone_id = var.primary_hosted_zone_id
  name    = "cdn.${var.route53_domain}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn_dist.domain_name
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}



resource "aws_s3_bucket_policy" "allow_public_frontend" {
  bucket = aws_s3_bucket.cdn.id
  policy = data.aws_iam_policy_document.public_frontend_policy.json
}