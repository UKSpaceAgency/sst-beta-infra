output "bucket_id" {
  value = aws_s3_bucket.data_bucket.id
}

output "bucket_arn" {
  value = aws_s3_bucket.data_bucket.arn
}

output "deployment_hist_bucket_id" {
  value = aws_s3_bucket.deployment_history.id
}

output "lambdas_bucket_id" {
  value = aws_s3_bucket.lambdas_bucket.id
}

output "log_bucket_id" {
  value = aws_s3_bucket.log_bucket.id
}

output "reentry_bucket_id" {
  value = aws_s3_bucket.reentry_data_bucket.id
}

output "reentry_bucket_arn" {
  value = aws_s3_bucket.reentry_data_bucket.arn
}