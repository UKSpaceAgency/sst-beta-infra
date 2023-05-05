module "ecs" {
  source   = "../../tf-modules/cluster"
  env_name = var.env_name
  container_insights_enabled = false
  custom_vpc_id              = module.network.custom_vpc_id
  logs_retention_days        = 14
}