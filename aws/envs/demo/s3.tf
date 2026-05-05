module "s3" {
  source   = "../../tf-modules/bucket"
  env_name = var.env_name
  cloudfront_deployments_arn = "arn:aws:cloudfront::469816118475:distribution/E1YGC9KRST5EYB"
}