module "db" {
  source   = "../../tf-modules/db"
  env_name = var.env_name
  vpc_security_group_ids = [module.network.pg-security-group-id]
  db_subnet_ids = module.network.private_subnet_ids
}