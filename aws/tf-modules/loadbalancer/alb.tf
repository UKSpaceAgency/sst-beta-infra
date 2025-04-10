data "aws_elb_service_account" "main" {}

data "aws_iam_policy_document" "alb_logs" {
  policy_id = "alb-logs-policy-for-${var.env_name}"
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.main.arn]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.elb_logs.arn}/${var.env_name}/AWSLogs/*"]
  }

  statement {
    actions = [
      "s3:PutObject"
    ]
    effect = "Allow"
    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
    condition {
      test     = "StringEquals"
      values   = ["bucket-owner-full-control"]
      variable = "s3:x-amz-acl"
    }
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.elb_logs.bucket}/*"
    ]
    sid = "AWSLogDeliveryWrite"
  }

  statement {
    actions = [
      "s3:GetBucketAcl"
    ]
    effect = "Allow"
    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.elb_logs.bucket}"
    ]
    sid = "AWSLogDeliveryAclCheck"
  }

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
      aws_s3_bucket.elb_logs.arn, "${aws_s3_bucket.elb_logs.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false"
      ]
    }
  }

  version = "2012-10-17"
}

resource "random_uuid" "some_uuid" {}

resource "aws_s3_bucket" "elb_logs" {
  bucket        = substr(format("%s-%s", "alb-logs-for-mys-env-${var.env_name}", replace(random_uuid.some_uuid.result, "-", "")), 0, 32)
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "elb_logs_versioning" {
  bucket = aws_s3_bucket.elb_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "expiration_rule_alb_logs" {
  bucket = aws_s3_bucket.elb_logs.id

  rule {
    id = "Cleanup"

    filter {
      prefix = "/"
    }

    expiration {
      days = 60
    }
    status = "Enabled"
  }

}

resource "aws_s3_bucket_logging" "elb_logs_logging" {
  bucket = aws_s3_bucket.elb_logs.id

  target_bucket = var.log_bucket_id
  target_prefix = "elb_logs_bucket/"
}

resource "aws_s3_bucket_policy" "allow_access_from_alb" {
  bucket = aws_s3_bucket.elb_logs.id
  policy = data.aws_iam_policy_document.alb_logs.json
}

resource "aws_lb" "alb" {
  name                       = "alb-${var.env_name}"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.allow_tls_only_sg_id, var.default_sg_id]
  subnets                    = var.public_subnet_ids
  enable_deletion_protection = true
  drop_invalid_header_fields = true

  access_logs {
    bucket  = aws_s3_bucket.elb_logs.bucket
    prefix  = var.env_name
    enabled = true
  }

}


resource "aws_lb_listener" "basic_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.domain_cert_arn

  tags = {
    name = "alb-${var.env_name}"
  }

  routing_http_response_server_enabled = false
  routing_http_response_strict_transport_security_header_value = "max-age=31536000; includeSubDomains; preload"
  routing_http_response_x_content_type_options_header_value = "nosniff"

  #routing_http_response_x_frame_options_header_value = "ALLOW-FROM https://${var.route53_domain}"
  routing_http_response_x_frame_options_header_value = "SAMEORIGIN"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Specify a route"
      status_code  = "503"
    }
  }
}
