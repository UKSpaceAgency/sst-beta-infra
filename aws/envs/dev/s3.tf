module "s3" {
  source   = "../../tf-modules/bucket"
  env_name = var.env_name
  cloudfront_deployments_arn = "arn:aws:cloudfront::915338536460:distribution/E1G73UHVKZWVTS"
}