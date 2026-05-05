module "s3" {
  source   = "../../tf-modules/bucket"
  env_name = var.env_name
  cloudfront_deployments_arn = "arn:aws:cloudfront::744996504263:distribution/EWVJN9RN9Y7NT"
}