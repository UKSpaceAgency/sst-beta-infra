resource "random_uuid" "some_uuid" {}

resource "aws_s3_bucket" "redirect" {
  bucket        = substr(format("%s-%s", "redirect-2-www-mys-${var.env_name}", replace(random_uuid.some_uuid.result, "-", "")), 0, 32)
  force_destroy = true
}


resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.redirect.id
  key          = "index.html"
  source       = "index.html"
  content_type = "text/html"
  etag         = filemd5("index.html")
}

resource "aws_cloudfront_function" "redirect_2_www_function" {
  name    = "redirect-2-www-function"
  runtime = "cloudfront-js-1.0"
  comment = "perm redirect"
  publish = true
  code    = file("cf_function.js")
}

resource "aws_cloudfront_origin_access_control" "s3_only_access_control" {
  name                              = "orig-s3-for-redirect-bucket"
  description                       = "Origin Access for redirect-bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "redirect_dist" {
  origin {
    domain_name              = aws_s3_bucket.redirect.bucket_regional_domain_name
    origin_id                = "redirect-2-www"
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
    target_origin_id       = "redirect-2-www"
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = data.aws_cloudfront_cache_policy.managed-caching-optimized.id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.redirect_2_www_function.arn
    }

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

  aliases             = [var.route53_domain]
  wait_for_deployment = false
  price_class         = "PriceClass_100"
  enabled             = true
  is_ipv6_enabled     = true
  http_version        = "http2"
  comment             = "redirect-2-www"
  default_root_object = "index.html"

}


resource "aws_route53_record" "redirect_itself" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = var.route53_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.redirect_dist.domain_name
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}


resource "aws_s3_bucket_policy" "allow_public_frontend" {
  bucket = aws_s3_bucket.redirect.id
  policy = data.aws_iam_policy_document.public_frontend_policy.json
}