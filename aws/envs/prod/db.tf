module "db" {
  source                 = "../../tf-modules/db"
  env_name               = var.env_name
  vpc_security_group_ids = [module.network.pg-security-group-id]
  db_subnet_ids          = module.network.private_subnet_ids
  instances_no           = 2
  default_delete_protection = true
  default_monitoring_interval = 60
  max_acu = 4
}