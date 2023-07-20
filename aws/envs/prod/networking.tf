module "network" {
  source     = "../../tf-modules/networking"
  env_name   = var.env_name
  cidr_block = "172.18.24.0/22"
  private_subnet_bits = 4
  public_subnet_bits = 4
}