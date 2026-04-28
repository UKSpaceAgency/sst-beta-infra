data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  reports_supporting_ap_name = "reports-supporting-${var.env_name}"
  reports_olap_name          = "reports-pretty-${var.env_name}"
  reports_olap_arn = format(
    "arn:aws:s3-object-lambda:%s:%s:accesspoint/%s",
    data.aws_region.current.name,
    data.aws_caller_identity.current.account_id,
    local.reports_olap_name,
  )
}

resource "aws_iam_role" "lambda-assume-role-json-pretty-print" {
  name = "iam-role-for-json-pretty-print-lambda"

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

# Permissions the Lambda needs: read the original object via the supporting
# access point, and deliver the transformed bytes back through the OLAP.
resource "aws_iam_role_policy" "json_pretty_print_lambda_inline" {
  name = "json-pretty-print-lambda-inline"
  role = aws_iam_role.lambda-assume-role-json-pretty-print.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "${aws_s3_access_point.reports_supporting_ap.arn}/object/*"
      },
      {
        Effect   = "Allow"
        Action   = "s3-object-lambda:WriteGetObjectResponse"
        Resource = local.reports_olap_arn
      },
    ]
  })
}

module "json_pretty_print_lambda" {
  source               = "../../../tf-modules/lambda_in_public"
  env_name             = var.env_name
  lambda_function_name = "json-pretty-print-${var.env_name}"
  lambda_handler_name  = "main.lambda_handler"
  lambda_policy_arn    = data.terraform_remote_state.stack.outputs.lambda_iam_policy_public_arn
  lambda_role_arn      = aws_iam_role.lambda-assume-role-json-pretty-print.arn
  lambda_role_name     = aws_iam_role.lambda-assume-role-json-pretty-print.name
  s3_bucket            = data.terraform_remote_state.stack.outputs.lambdas_bucket_id
  s3_key               = "json-pretty-print-${var.image_tag}.zip"
  runtime              = "python3.11"
  lambda_memory_size   = 256
  timeout              = 30

  env_vars = {}
}

# Supporting access point — sits in front of the reentry/reports bucket and
# is what the Object Lambda reads through.
resource "aws_s3_access_point" "reports_supporting_ap" {
  bucket = data.terraform_remote_state.stack.outputs.s3_reentry_bucket_id
  name   = local.reports_supporting_ap_name
}

# Object Lambda Access Point — this is the ARN the BE generates presigned
# URLs against. Every GetObject through it invokes the Lambda above.
resource "aws_s3control_object_lambda_access_point" "reports_olap" {
  name = local.reports_olap_name

  configuration {
    supporting_access_point = aws_s3_access_point.reports_supporting_ap.arn

    transformation_configuration {
      actions = ["GetObject"]

      content_transformation {
        aws_lambda {
          function_arn = module.json_pretty_print_lambda.public_lambda_arn
        }
      }
    }
  }
}

# Allow the ECS task role (the BE) to read through the OLAP — both the
# s3-object-lambda action and the underlying s3:GetObject on the supporting AP.
resource "aws_iam_role_policy" "ecs_task_read_reports_olap" {
  name = "ecs-task-read-reports-olap"
  role = "ecs-task-role-for-${var.env_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3-object-lambda:GetObject"
        Resource = aws_s3control_object_lambda_access_point.reports_olap.arn
      },
      {
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "${aws_s3_access_point.reports_supporting_ap.arn}/object/*"
      },
    ]
  })
}

output "reports_object_lambda_access_point_arn" {
  value = aws_s3control_object_lambda_access_point.reports_olap.arn
}
