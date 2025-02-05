locals {
  space_track_namespace         = "space-track"
  esa_discos_namespace          = "esa-discos"
  notifications_namespace       = "notifications"
  six_hours_in_seconds          = 60 * 60 * 6
  six_and_half_hours_in_seconds = 60 * 60 * 6.5
  fourteen_hours_in_seconds     = 60 * 60 * 14
  one_day_in_seconds            = 60 * 60 * 24 #24hrs
  twenty_five_hrs_in_seconds    = 60 * 60 * 25
}

module "space_track_no_cdms" {
  source                 = "../alarm_metric"
  cluster_log_group_name = var.cluster_log_group_name
  env_name               = var.env_name
  alarm_name             = "No CDMs have been ingested in last 6 hours"
  alarm_description      = "No CDMs have been ingested in last 6 hours"
  metric_filter_name     = "cdms_iterator_yielding_cdm"
  metric_filter_pattern  = "cdms_iterator yielding cdm"
  metric_name            = "ingested-cdms"
  metric_namespace       = local.space_track_namespace
  period_in_seconds      = local.six_hours_in_seconds
}

module "esa_discos_ingestion_finished" {
  source                 = "../alarm_metric"
  cluster_log_group_name = var.cluster_log_group_name
  env_name               = var.env_name
  alarm_name             = "No ingestion of Satellites from ESA-Discos has been completed in last 14 hours"
  alarm_description      = "No ingestion of Satellites from ESA-Discos has been completed in last 14 hours"
  metric_filter_name     = "esa-discos-ingestion-finished"
  metric_filter_pattern  = "Finished pulling satellite data from ESA Discos"
  metric_name            = "ingestion-finished"
  metric_namespace       = local.esa_discos_namespace
  period_in_seconds      = local.fourteen_hours_in_seconds
}

module "notifications_sending_finished" {
  source                 = "../alarm_metric"
  cluster_log_group_name = var.cluster_log_group_name
  env_name               = var.env_name
  alarm_name             = "No sending of Notifications have been finished in the last 24 hours"
  alarm_description      = "No sending of Notifications have been finished in the last 24 hours"
  metric_filter_name     = "notifications-sending-finished"
  metric_filter_pattern  = "%Finished sending notifications%"
  metric_name            = "sending-finished"
  metric_namespace       = local.notifications_namespace
  period_in_seconds      = local.one_day_in_seconds
  default_statistic      = "Maximum"
}

module "space_track_satellites_ingestion_finished" {
  source                 = "../alarm_metric"
  cluster_log_group_name = var.cluster_log_group_name
  env_name               = var.env_name
  alarm_name             = "No ingestion of Satellites from Space-Track has been completed in last 25 hours"
  alarm_description      = "No ingestion of Satellites from Space-Track has been completed in last 25 hours"
  metric_filter_name     = "space-track-satellites-ingestion-finished"
  metric_filter_pattern  = "%Finished pulling Satellites from SpaceTrack%"
  metric_name            = "satellites-ingestion-finished"
  metric_namespace       = local.space_track_namespace
  period_in_seconds      = local.twenty_five_hrs_in_seconds
  default_statistic      = "Maximum"
}

module "space_track_ingestion_finished" {
  source                 = "../alarm_metric"
  cluster_log_group_name = var.cluster_log_group_name
  env_name               = var.env_name
  alarm_name             = "No ingestion of CDMs has been completed in the last 6.5 hours"
  alarm_description      = "No ingestion of CDMs has been completed in the last 6.5 hours"
  metric_filter_name     = "sync_with_space_track_cdms_finished"
  metric_filter_pattern  = "%Finished pulling CDMs from Space-Track%"
  metric_name            = "ingestion-finished"
  metric_namespace       = local.space_track_namespace
  period_in_seconds      = local.six_and_half_hours_in_seconds
  default_statistic      = "Maximum"
}