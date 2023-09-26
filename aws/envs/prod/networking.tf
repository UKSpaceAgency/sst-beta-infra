module "network" {
  source     = "../../tf-modules/networking"
  env_name   = var.env_name
  cidr_block = "172.20.0.0/16"
}