output "bucket_id" {
  value = aws_s3_bucket.data_bucket.id
}

output "bucket_arn" {
  value = aws_s3_bucket.data_bucket.arn
}

output "deployment_hist_bucket_id" {
  value = aws_s3_bucket.deployment_history.id
}