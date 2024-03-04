locals {
  six_hours_in_seconds = 60*60*6
  space_track_namespace = "space-track"
  no_cdms_metric_name = "ingested-cdms"
}

resource "aws_cloudwatch_metric_alarm" "no_cdms_ingested_metric_alarm" {
  alarm_name                = "No CDMs have been ingested in last 6 hours"
  comparison_operator       = "LessThanOrEqualToThreshold"
  evaluation_periods        = 1
  metric_name               = local.no_cdms_metric_name
  namespace                 = local.space_track_namespace
  period                    = local.six_hours_in_seconds
  statistic                 = "Sum"
  threshold                 = "0"
  alarm_description         = "No CDMs have been ingested in last 6 hours"
  insufficient_data_actions = []

}

resource "aws_cloudwatch_log_metric_filter" "cdms_iterator_yielding_cdm_metric_filter" {
  name           = "cdms_iterator_yielding_cdm"
  pattern        = "cdms_iterator yielding cdm"
  log_group_name = var.cluster_log_group_name

  metric_transformation {
    name      = local.no_cdms_metric_name
    namespace = local.space_track_namespace
    value     = "1"
    default_value = "0"
    unit = "Count"
  }
}