resource "aws_cloudwatch_metric_alarm" "data_cache_oldest_age_24h" {
  alarm_name          = "Data Cache Client Queue reached 24hrs old"
  alarm_description   = "Fires when the oldest message in data-dev is >= 24 hours old."
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateAgeOfOldestMessage"
  statistic           = "Maximum"
  period              = 300
  evaluation_periods  = 3
  datapoints_to_alarm = 3
  threshold           = 86400
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = local.target_sqs_name
  }

}

resource "aws_cloudwatch_metric_alarm" "sqs_not_visible_spike" {
  alarm_name          = "sqs-not-visible-messages-spike"
  alarm_description   = "Alarm when ApproximateNumberOfMessagesNotVisible > 100 (potential processing backlog spike)"

  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesNotVisible"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 2
  threshold           = 100
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    QueueName = local.target_sqs_name
  }

  treat_missing_data = "notBreaching"
}