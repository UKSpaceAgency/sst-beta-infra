module "alb" {
  source   = "../../tf-modules/loadbalancer"
  env_name = var.env_name
  allow_tls_only_sg_id = module.network.allow_tls_only_sg_id
  default_sg_id = module.network.default_sg_id
  domain_cert_arn = module.route53.main_cert_arn
  public_subnet_ids = module.network.public_subnet_ids
}