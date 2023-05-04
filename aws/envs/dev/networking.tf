module "network" {
  source   = "../../tf-modules/networking"
  env_name = var.env_name
}