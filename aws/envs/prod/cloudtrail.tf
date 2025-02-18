module "cloudtrail" {
  source        = "../../tf-modules/cloudtrail"
  env_name      = var.env_name
  log_bucket_id = module.s3.log_bucket_id
  include_global = true
}