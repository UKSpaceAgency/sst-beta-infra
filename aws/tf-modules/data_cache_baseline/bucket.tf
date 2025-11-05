resource "random_uuid" "some_uuid" {}

resource "aws_s3_bucket" "data_cache_bucket" {
  bucket        = substr(format("%s-%s", "data-cache-${var.env_name}", replace(random_uuid.some_uuid.result, "-", "")), 0, 32)
  force_destroy = true
}

