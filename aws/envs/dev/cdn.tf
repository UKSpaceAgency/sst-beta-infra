module "cdn" {
  source                 = "../../tf-modules/cdn_cloudfront"
  env_name               = var.env_name
  primary_hosted_zone_id = module.route53.primary_zone_id
  us_east_1_cert_arn     = aws_acm_certificate.cf_cert.arn
  route53_domain         = var.route53_domain
  alb_domain_name        = module.alb.alb_dns_name
}