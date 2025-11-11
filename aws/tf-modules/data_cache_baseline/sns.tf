data "aws_iam_policy_document" "topic_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions   = ["SNS:Publish"]
    resources = ["arn:aws:sns:*:*:data-cache-${var.env_name}"]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.data_cache_bucket.arn]
    }
  }

  statement {
    effect = "Allow"
    sid = "AllowSubscribeFromDevSQS"

    principals {
      type        = "AWS"
      identifiers = ["915338536460"]
    }

    actions   = ["SNS:Subscribe"]
    resources = ["arn:aws:sns:*:*:data-cache-${var.env_name}"]

    condition {
      test     = "StringLike"
      variable = "sns:Endpoint"
      values   = ["arn:aws:sqs:eu-west-2:915338536460:data-cache-*"]
    }
  }

  statement {
    effect = "Allow"
    sid = "AllowSubscribeFromDevDemo"

    principals {
      type        = "AWS"
      identifiers = ["469816118475"]
    }

    actions   = ["SNS:Subscribe"]
    resources = ["arn:aws:sns:*:*:data-cache-${var.env_name}"]

    condition {
      test     = "StringLike"
      variable = "sns:Endpoint"
      values   = ["arn:aws:sqs:eu-west-2:469816118475:data-cache-*"]
    }
  }
}

resource "aws_sns_topic" "data-cache-topic-dispatcher" {
  name = "data-cache-${var.env_name}"
  policy = data.aws_iam_policy_document.topic_policy.json
}


resource "aws_s3_bucket_notification" "bucket_notification_to_sns" {
 bucket = aws_s3_bucket.data_cache_bucket.id

  topic {
    topic_arn     = aws_sns_topic.data-cache-topic-dispatcher.arn
    events        = ["s3:ObjectCreated:*"]
  }
}
