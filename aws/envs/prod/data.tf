
data "aws_route53_zone" "primary" {
  name         = var.route53_domain
  private_zone = false
}

data "aws_iam_policy_document" "public_frontend_policy" {
  policy_id = "PolicyPublicFrontend11155"
  statement {
    sid    = "AllowCloudFrontServicePrincipalReadOnly"
    effect = "Allow"
    principals {
      identifiers = ["cloudfront.amazonaws.com"]
      type        = "Service"
    }
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.redirect.bucket}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.redirect_dist.arn]
    }
  }
}


data "aws_cloudfront_cache_policy" "managed-caching-disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_cache_policy" "managed-caching-optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_origin_request_policy" "managed-all-viewer" {
  name = "Managed-AllViewer"
}