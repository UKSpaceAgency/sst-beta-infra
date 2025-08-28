resource "random_uuid" "some_uuid" {}

resource "aws_s3_bucket" "log_bucket" {
  bucket        = substr(format("%s-%s", "log-bucket-${var.env_name}", replace(random_uuid.some_uuid.result, "-", "")), 0, 32)
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "log_bucket_versioning" {
  bucket = aws_s3_bucket.log_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

#expire everything in log bucket after 1w
resource "aws_s3_bucket_lifecycle_configuration" "expiration_rule" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    id = "Cleanup"

    filter {
      prefix = "/"
    }

    expiration {
      days = 7
    }
    status = "Enabled"
  }

}

resource "aws_s3_bucket_ownership_controls" "log_bucket_ownership" {
  bucket = aws_s3_bucket.log_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "log_bucket_acl" {
  bucket = aws_s3_bucket.log_bucket.id
  acl    = "log-delivery-write"

  depends_on = [aws_s3_bucket_ownership_controls.log_bucket_ownership]

}

resource "aws_s3_bucket" "data_bucket" {
  bucket        = substr(format("%s-%s", "mys-bucket-${var.env_name}-tg", replace(random_uuid.some_uuid.result, "-", "")), 0, 32)
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "data_bucket_versioning" {
  bucket = aws_s3_bucket.data_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "data_bucket_logging" {
  bucket = aws_s3_bucket.data_bucket.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "data_bucket/"
}

data "aws_iam_policy_document" "deny_pure_http_traffic" {
  statement {

    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:*"
    ]

    resources = [
      aws_s3_bucket.data_bucket.arn, "${aws_s3_bucket.data_bucket.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false"
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "data_bucket_policy" {
  bucket = aws_s3_bucket.data_bucket.id
  policy = data.aws_iam_policy_document.deny_pure_http_traffic.json
}

//deployment history bucket
resource "aws_s3_bucket" "deployment_history" {
  bucket        = substr(format("%s-%s", "mys-deployment-history-${var.env_name}", replace(random_uuid.some_uuid.result, "-", "")), 0, 32)
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "deployment_history_versioning" {
  bucket = aws_s3_bucket.deployment_history.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "deployment_history_logging" {
  bucket = aws_s3_bucket.deployment_history.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "deployment_history/"
}

resource "aws_s3_bucket_cors_configuration" "cost_for_bucket" {
  bucket = aws_s3_bucket.deployment_history.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["https://${aws_s3_bucket.deployment_history.bucket_regional_domain_name}"]
    expose_headers  = ["Last-Modified"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_ownership_controls" "own_ctrl" {
  bucket = aws_s3_bucket.deployment_history.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "public_enabled" {
  bucket = aws_s3_bucket.deployment_history.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.own_ctrl,
    aws_s3_bucket_public_access_block.public_enabled,
  ]

  bucket = aws_s3_bucket.deployment_history.id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "allow_listing" {
  bucket = aws_s3_bucket.deployment_history.id
  policy = data.aws_iam_policy_document.allow_listing_policy_doc.json
}

data "aws_iam_policy_document" "allow_listing_policy_doc" {
  statement {

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.deployment_history.arn,
      "${aws_s3_bucket.deployment_history.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "true"
      ]
    }
  }
}

resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.deployment_history.id
  key          = "index.html"
  source       = "files/index.html"
  content_type = "text/html"

  etag = filemd5("files/index.html")
}

resource "aws_s3_object" "config_js" {
  bucket       = aws_s3_bucket.deployment_history.id
  key          = "config.js"
  content      = "export const S3_BUCKET_URL = 'https://${aws_s3_bucket.deployment_history.bucket_regional_domain_name}/';"
  content_type = "text/javascript"
}

resource "aws_s3_bucket" "lambdas_bucket" {
  bucket        = substr(format("%s-%s", "mys-lambdas-${var.env_name}", replace(random_uuid.some_uuid.result, "-", "")), 0, 32)
  force_destroy = true
}

data "aws_iam_policy_document" "deny_pure_http_traffic_lambda_bucket" {
  statement {

    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:*"
    ]

    resources = [
      aws_s3_bucket.lambdas_bucket.arn, "${aws_s3_bucket.lambdas_bucket.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false"
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "lambda_bucket_policy" {
  bucket = aws_s3_bucket.lambdas_bucket.id
  policy = data.aws_iam_policy_document.deny_pure_http_traffic_lambda_bucket.json
}

resource "aws_s3_bucket_versioning" "lambdas_bucket_versioning" {
  bucket = aws_s3_bucket.lambdas_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "lambdas_bucket_logging" {
  bucket = aws_s3_bucket.lambdas_bucket.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "lambdas_bucket/"
}

resource "aws_s3_bucket_lifecycle_configuration" "lambdas_bucket_export" {
  bucket = aws_s3_bucket.lambdas_bucket.id

  rule {
    id     = "delete-after-1y"

    filter {
      prefix = "/"
    }
    status = "Enabled"


    expiration {
      days = 365
    }

    # Exclude objects tagged as keep=true
    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
}

resource "aws_s3_bucket" "reentry_data_bucket" {
  bucket        = substr(format("%s-%s", "mys-reentry-${var.env_name}", replace(random_uuid.some_uuid.result, "-", "")), 0, 32)
  force_destroy = true
}
