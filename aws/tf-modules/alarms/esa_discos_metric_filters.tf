locals {
  fourteen_hours_in_seconds = 60*60*14
  esa_discos_namespace = "esa_discos"
  ingestion_finished_metric_name = "ingestion-finished"
}

resource "aws_cloudwatch_metric_alarm" "ingestion_finished_metric_alarm" {
  alarm_name                = "No ingestion of Satellites from ESA-Discos has been completed in last 14 hours"
  comparison_operator       = "LessThanOrEqualToThreshold"
  evaluation_periods        = 1
  metric_name               = local.ingestion_finished_metric_name
  namespace                 = local.esa_discos_namespace
  period                    = local.fourteen_hours_in_seconds
  statistic                 = "Sum"
  threshold                 = "0"
  alarm_description         = "No ingestion of Satellites from ESA-Discos has been completed in last 14 hours"
  insufficient_data_actions = []

}

resource "aws_cloudwatch_log_metric_filter" "ingestion_finished_metric_filter" {
  name           = "esa-discos-ingestion-finished"
  pattern        = "Finished pulling satellite data from ESA Discos"
  log_group_name = var.cluster_log_group_name

  metric_transformation {
    name      = local.ingestion_finished_metric_name
    namespace = local.esa_discos_namespace
    value     = "1"
    default_value = "0"
    unit = "Count"
  }
}