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