
resource "aws_iam_role" "lambda-assume-role-geojson-lambda" {
  name = "iam-role-for-geojson-lambda"

  assume_role_policy = jsonencode(
    {
      Version : "2012-10-17",
      Statement : [
        {
          Action : "sts:AssumeRole",
          Principal : {
            Service : "lambda.amazonaws.com"
          },
          Effect : "Allow",
          Sid : ""
        }
      ]
    }
  )
}

resource "aws_iam_policy" "lambda-iam-policy-geojson" {
  name        = "iam-policy-for-geojson-lambda"
  path        = "/"
  description = "IAM policy for geojson lambda"

  policy = jsonencode(
    {
      Version : "2012-10-17",
      Statement : [
        {
          Action : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          Resource : "arn:aws:logs:*:*:*",
          Effect : "Allow"
        },
        {
          "Action": [
            "s3:*"
          ],
          "Effect": "Allow",
          "Resource": [
            data.terraform_remote_state.stack.outputs.s3_reentry_bucket_arn,
            "${data.terraform_remote_state.stack.outputs.s3_reentry_bucket_arn}/*",
            data.terraform_remote_state.stack.outputs.cdn_bucket_arn,
            "${data.terraform_remote_state.stack.outputs.cdn_bucket_arn}/*"

          ]
        }
      ]
    }
  )
}

module "geojson_lambda" {
  source               = "../../../tf-modules/lambda_in_public"
  env_name             = var.env_name
  lambda_function_name = "generate-geojson-${var.env_name}"
  lambda_handler_name  = "main.lambda_handler"
  lambda_policy_arn    = aws_iam_policy.lambda-iam-policy-geojson.arn
  lambda_role_arn      = aws_iam_role.lambda-assume-role-notifications-sender.arn
  lambda_role_name     = aws_iam_role.lambda-assume-role-notifications-sender.name
  s3_bucket            = data.terraform_remote_state.stack.outputs.lambdas_bucket_id
  s3_key               = "generate-geojson-files-${var.image_tag}.zip"
  runtime              = "python3.13"
  lambda_memory_size   = 512

  env_vars = {
    "ENVIRONMENT_NAME" = upper(var.env_name),
    "SOURCE_BUCKET_NAME" = data.terraform_remote_state.stack.outputs.s3_reentry_bucket_id,
    "DESTINATION_BUCKET_NAME" = data.terraform_remote_state.stack.outputs.cdn_bucket_id,
  }
}

# resource "aws_lambda_permission" "allow_bucket_to_geojson_lambda" {
#   statement_id  = "AllowExecutionFromS3Bucket"
#   action        = "lambda:InvokeFunction"
#   function_name = module.geojson_lambda.public_lambda_name
#   principal     = "s3.amazonaws.com"
#   source_arn    = data.terraform_remote_state.stack.outputs.s3_reentry_bucket_arn
# }
#
# resource "aws_s3_bucket_notification" "bucket_notification_geojson_lambda" {
#  bucket = data.terraform_remote_state.stack.outputs.s3_reentry_bucket_id
#
#  eventbridge = true
#
#  lambda_function {
#    lambda_function_arn = module.geojson_lambda.public_lambda_arn
#    events              = ["s3:ObjectCreated:*"]
#    filter_prefix       = "reentry_event_reports/"
#    filter_suffix       = ".json"
#  }
# }