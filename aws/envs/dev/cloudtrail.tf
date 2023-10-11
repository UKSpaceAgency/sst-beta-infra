module "cloudtrail" {
  source   = "../../tf-modules/cloudtrail"
  env_name = var.env_name
}