resource "aws_cloudwatch_metric_alarm" "bucket_1_alarm" {
  alarm_name                = "Conjunctions bucket malware detection"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 1
  metric_name               = "InfectedScanCount"
  namespace                 = "AWS/GuardDuty/MalwareProtection"
  period                    = 60
  statistic                 = "Sum"
  threshold                 = 0
  alarm_description         = "GuardDuty Malware detection for ${var.bucket_1_id}"
  insufficient_data_actions = []
  treat_missing_data        = "notBreaching"
  dimensions = {
    "Resource Name" = var.bucket_1_id
    "Malware Protection Plan Id"  = aws_guardduty_malware_protection_plan.s3_protection_1.id
  }
}

resource "aws_cloudwatch_metric_alarm" "bucket_2_alarm" {
  alarm_name                = "Re-entries bucket malware detection"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 1
  metric_name               = "InfectedScanCount"
  namespace                 = "AWS/GuardDuty/MalwareProtection"
  period                    = 60
  statistic                 = "Sum"
  threshold                 = 0
  alarm_description         = "GuardDuty Malware detection for ${var.bucket_2_id}"
  insufficient_data_actions = []
  treat_missing_data        = "notBreaching"
  dimensions = {
    "Resource Name" = var.bucket_2_id
    "Malware Protection Plan Id"  = aws_guardduty_malware_protection_plan.s3_protection_2.id
  }
}