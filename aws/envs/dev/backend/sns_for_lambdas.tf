data "aws_iam_policy_document" "topic_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions   = ["SNS:Publish"]
    resources = ["arn:aws:sns:*:*:lambda-dispatcher-topic-${var.env_name}"]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [data.terraform_remote_state.stack.outputs.s3_reentry_bucket_arn]
    }
  }
}

resource "aws_sns_topic" "lambda_dispatcher" {
  name = "lambda-dispatcher-topic-${var.env_name}"
  policy = data.aws_iam_policy_document.topic_policy.json
}


resource "aws_s3_bucket_notification" "bucket_notification_to_sns" {
 bucket = data.terraform_remote_state.stack.outputs.s3_reentry_bucket_id

 eventbridge = true

  topic {
    topic_arn     = aws_sns_topic.lambda_dispatcher.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix       = "reentry_event_reports/"
    filter_suffix       = ".json"
  }
}

//subscriptions

//geojson lambda
resource "aws_sns_topic_subscription" "geojson_lambda_target" {
  topic_arn = aws_sns_topic.lambda_dispatcher.arn
  protocol  = "lambda"
  endpoint  = module.geojson_lambda.public_lambda_arn
}

//selenium lambda
resource "aws_sns_topic_subscription" "selenium_lambda_target" {
  topic_arn = aws_sns_topic.lambda_dispatcher.arn
  protocol  = "lambda"
  endpoint  = module.selenium_lambda.public_lambda_arn
}


