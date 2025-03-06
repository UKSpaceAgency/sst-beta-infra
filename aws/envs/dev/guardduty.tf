module "guardduty" {
  source        = "../../tf-modules/guardduty_s3"

  bucket_1_id         = module.s3.bucket_id
  bucket_2_id         = module.s3.reentry_bucket_id
  guard_duty_role_arn = module.iam.guard_duty_malware_protection_s3_role_arn
}