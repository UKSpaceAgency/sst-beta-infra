data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

resource "random_uuid" "some_uuid" {}

resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket = substr(format("%s-%s", "mys-${var.env_name}-cloudtrail", replace(random_uuid.some_uuid.result, "-", "")), 0, 32)
  force_destroy = true
}

data "aws_iam_policy_document" "cloud_trail_policy_document" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail_bucket.arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/account-trail-for-${var.env_name}"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudtrail_bucket.arn}/prefix/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/account-trail-for-${var.env_name}"]
    }
  }
}
resource "aws_s3_bucket_policy" "cloud_trail_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  policy = data.aws_iam_policy_document.cloud_trail_policy_document.json
}

resource "aws_cloudtrail" "account-trail" {
  name                          = "account-trail-for-${var.env_name}"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.id
  include_global_service_events = var.include_global
  s3_key_prefix = "prefix"

  depends_on = [
    aws_s3_bucket_policy.cloud_trail_bucket_policy
  ]
}

