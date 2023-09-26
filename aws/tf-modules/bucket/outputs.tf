output "bucket_id" {
  value = aws_s3_bucket.data_bucket.id
}

output "deployment_hist_bucket_id" {
  value = aws_s3_bucket.deployment_history.id
}