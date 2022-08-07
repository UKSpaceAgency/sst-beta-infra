
module "public_route53_hosted_zone" {
  source         = "./modules/public_route53_hosted_zone"
  name           = "monitor-your-satellites.service.gov.uk"
  product_domain = "mys-prod"
  environment    = "prod"

}
