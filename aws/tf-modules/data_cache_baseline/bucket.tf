resource "random_uuid" "some_uuid" {}

resource "aws_s3_bucket" "data_cache_bucket" {
  bucket        = substr(format("%s-%s", "data-cache-${var.env_name}", replace(random_uuid.some_uuid.result, "-", "")), 0, 32)
  force_destroy = true
}

data "aws_iam_policy_document" "data_cache_bucket_policy" {
  statement {
    sid = "DenyNonHttpsTraffic"
    effect = "Deny"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:*"
    ]
    resources = [
      aws_s3_bucket.data_cache_bucket.arn, "${aws_s3_bucket.data_cache_bucket.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false"
      ]
    }
  }

  statement {
    sid = "AllowGetFromDevAccount"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::915338536460:role/ecs-task-role-for-dev"]
    }
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.data_cache_bucket.arn}/*"
    ]
  }

  statement {
    sid = "AllowGetFromDemoAccount"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::469816118475:role/ecs-task-role-for-demo"]
    }
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.data_cache_bucket.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "data_cache_bucket_policy" {
  bucket = aws_s3_bucket.data_cache_bucket.id
  policy = data.aws_iam_policy_document.data_cache_bucket_policy.json
}