data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  target_sqs_name = "data-cache-client-${var.env_name}"
}

data "aws_iam_policy_document" "q_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions   = ["SQS:SendMessage"]
    resources = ["arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${local.target_sqs_name}"]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [var.data-cache-sns-topic-arn]
    }
  }
}

resource "aws_sqs_queue" "terraform_queue" {
  name                      = local.target_sqs_name
  message_retention_seconds = var.sqs_retention_seconds
  visibility_timeout_seconds = var.sqs_visibility_timeout_seconds
  policy = data.aws_iam_policy_document.q_policy.json
}

resource "aws_sns_topic_subscription" "sqs_to_sns_subscription" {
  topic_arn = var.data-cache-sns-topic-arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.terraform_queue.arn
}