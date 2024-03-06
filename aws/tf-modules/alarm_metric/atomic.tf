resource "aws_cloudwatch_metric_alarm" "metric_alarm" {
  alarm_name                = var.alarm_name
  comparison_operator       = var.default_comparison_operator
  evaluation_periods        = 1
  metric_name               = var.metric_name
  namespace                 = var.metric_namespace
  period                    = var.period_in_seconds
  statistic                 = var.default_statistic
  threshold                 = "0"
  alarm_description         = var.alarm_description
  insufficient_data_actions = []

}

resource "aws_cloudwatch_log_metric_filter" "metric_filter" {
  name           = var.metric_filter_name
  pattern        = var.metric_filter_pattern
  log_group_name = var.cluster_log_group_name

  metric_transformation {
    name          = var.metric_name
    namespace     = var.metric_namespace
    value         = "1"
    default_value = "0"
    unit          = var.default_unit
  }
}