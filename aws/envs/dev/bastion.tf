locals {
  first_public_subnet_id = element(module.network.public_subnet_ids, 0)
}

module "bastion" {
  source   = "../../tf-modules/bastion"
  env_name = var.env_name
  vpc_security_group_ids = [module.network.ssh-security-group-id]
  public_subnet_id = local.first_public_subnet_id
}