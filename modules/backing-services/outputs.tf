output "db" {
  value = cloudfoundry_service_instance.db
}

output "s3" {
  value = cloudfoundry_service_instance.aws_s3_bucket
}

output "logit" {
  value = cloudfoundry_user_provided_service.logit
}