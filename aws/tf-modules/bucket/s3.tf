resource "random_uuid" "some_uuid" {}

resource "aws_s3_bucket" "data_bucket" {
  bucket = substr(format("%s-%s", "mys-bucket-${var.env_name}-tg", replace(random_uuid.some_uuid.result, "-", "")), 0, 32)
  force_destroy = true
}