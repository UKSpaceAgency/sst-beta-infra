module "db" {
  source                 = "../../tf-modules/db"
  env_name               = var.env_name
  vpc_security_group_ids = [module.network.pg-security-group-id]
  db_subnet_ids          = module.network.private_subnet_ids
  instances_no           = 1
  max_acu                = 4
  default_delete_protection = true
  performance_insights_enabled = false
}