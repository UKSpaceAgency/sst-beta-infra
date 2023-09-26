data "aws_iam_policy" "secrets-manager" {
  name = "SecretsManagerReadWrite"
}

data "aws_iam_policy" "s3-full-access" {
  name = "AmazonS3FullAccess"
}

resource "aws_iam_policy" "access-secrets-from-ecs" {
  name   = "access-secrets-from-ecs"
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : [
          "secretsmanager:GetSecretValue",
          "kms:Decrypt"
        ],
        Resource : [
          "arn:aws:secretsmanager:*:*:*:*",
          "arn:aws:kms:*:*:*"
        ]
      }
    ]
  })

}

resource "aws_iam_policy" "allow_ecs_command_execution" {
  name   = "allow_ecs_command_execution"
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource : [
          "*"
        ]
      }
    ]
  })

}

resource "aws_iam_role" "ecs-task-role" {
  name = "ecs-task-role-for-${var.env_name}"

  managed_policy_arns = [data.aws_iam_policy.secrets-manager.arn, data.aws_iam_policy.s3-full-access.arn, aws_iam_policy.allow_ecs_command_execution.arn]
  assume_role_policy  = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Sid       = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

}


data "aws_iam_policy" "ecs-task-exec" {
  name = "AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy" "ec2-service-role" {
  name = "AmazonEC2ContainerServiceRole"
}

resource "aws_iam_role" "ecs-execution-role" {
  name = "ecs-execution-role-for-${var.env_name}"

  managed_policy_arns = [
    data.aws_iam_policy.ecs-task-exec.arn, data.aws_iam_policy.ec2-service-role.arn,
    aws_iam_policy.access-secrets-from-ecs.arn
  ]

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Sid       = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

}

data "aws_iam_policy_document" "assume_role_events" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_events" {
  name               = "ecs_events_role-for-${var.env_name}"

  managed_policy_arns = [
    data.aws_iam_policy.ecs-task-exec.arn, data.aws_iam_policy.ec2-service-role.arn,
    aws_iam_policy.access-secrets-from-ecs.arn
  ]

  assume_role_policy = data.aws_iam_policy_document.assume_role_events.json
}

resource "aws_iam_policy" "developers_policy" {
  name        =  "developers-policy-limited-mfa"
  description = "Developer accesspolicy"

  policy = jsonencode(
        {
          "Statement": [
            {
              "Action": [
                "s3:*"
              ],
              "Effect": "Allow",
              "Resource": "*",
              "Sid": "s3fullAccess"
            },
            {
              "Action": [
                "secretsmanager:Get*",
                "secretsmanager:List*",
                "secretsmanager:Describe*"
              ],
              "Condition": {
                "Bool": {
                  "aws:MultiFactorAuthPresent": "true"
                }
              },
              "Effect": "Allow",
              "Resource": "*",
              "Sid": "SecretManagerViewOnly"
            },
            {
              "Action": [
                "logs:GetLogEvents",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:Filter*",
                "cloudwatch:Describe*",
                "cloudwatch:Get*",
                "cloudwatch:List*"
              ],
              "Condition": {
                "Bool": {
                  "aws:MultiFactorAuthPresent": "true"
                }
              },
              "Effect": "Allow",
              "Resource": "*",
              "Sid": "CloudwatchReadOnly"
            },
            {
              "Action": [
                "ecs:Get*",
                "ecs:Describe*",
                "ecs:List*"
              ],
              "Condition": {
                "Bool": {
                  "aws:MultiFactorAuthPresent": "true"
                }
              },
              "Effect": "Allow",
              "Resource": "*",
              "Sid": "EcsReadOnly"
            },
            {
              "Action": [
                "iam:ChangePassword"
              ],
              "Effect": "Allow",
              "Resource": [
                "arn:aws:iam::*:user/$${aws:username}"
              ],
              "Sid": "IAMChangePassword"
            },
            {
              "Action": [
                "iam:GetAccountPasswordPolicy"
              ],
              "Effect": "Allow",
              "Resource": "*",
              "Sid": "GetPasswordPolicy"
            },
            {
              "Action": [
                "iam:ListUsers",
                "iam:ListVirtualMFADevices"
              ],
              "Effect": "Allow",
              "Resource": "*",
              "Sid": "AllowListActions"
            },
            {
              "Action": [
                "iam:CreateAccessKey",
                "iam:DeleteAccessKey",
                "iam:ListAccessKeys",
                "iam:UpdateAccessKey"
              ],
              "Condition": {
                "Bool": {
                  "aws:MultiFactorAuthPresent": "true"
                }
              },
              "Effect": "Allow",
              "Resource": "arn:aws:iam::*:user/$${aws:username}",
              "Sid": "AllowManageOwnAccessKeys"
            },
            {
              "Action": [
                "iam:DeleteSSHPublicKey",
                "iam:GetSSHPublicKey",
                "iam:ListSSHPublicKeys",
                "iam:UpdateSSHPublicKey",
                "iam:UploadSSHPublicKey"
              ],
              "Condition": {
                "Bool": {
                  "aws:MultiFactorAuthPresent": "true"
                }
              },
              "Effect": "Allow",
              "Resource": "arn:aws:iam::*:user/$${aws:username}",
              "Sid": "AllowManageOwnSSHPublicKeys"
            },
            {
              "Action": [
                "iam:ListMFADevices"
              ],
              "Effect": "Allow",
              "Resource": [
                "arn:aws:iam::*:mfa/*",
                "arn:aws:iam::*:user/$${aws:username}"
              ],
              "Sid": "AllowIndividualUserToListOnlyTheirOwnMFA"
            },
            {
              "Action": [
                "iam:CreateVirtualMFADevice",
                "iam:DeleteVirtualMFADevice",
                "iam:EnableMFADevice",
                "iam:ResyncMFADevice"
              ],
              "Effect": "Allow",
              "Resource": [
                "arn:aws:iam::*:mfa/*",
                "arn:aws:iam::*:user/$${aws:username}"
              ],
              "Sid": "AllowIndividualUserToManageTheirOwnMFA"
            },
            {
              "Action": [
                "iam:DeactivateMFADevice"
              ],
              "Condition": {
                "Bool": {
                  "aws:MultiFactorAuthPresent": "true"
                }
              },
              "Effect": "Allow",
              "Resource": [
                "arn:aws:iam::*:mfa/*",
                "arn:aws:iam::*:user/$${aws:username}"
              ],
              "Sid": "AllowIndividualUserToDeactivateOnlyTheirOwnMFAOnlyWhenUsingMFA"
            },
            {
              "Condition": {
                "BoolIfExists": {
                  "aws:MultiFactorAuthPresent": "false"
                }
              },
              "Effect": "Deny",
              "NotAction": [
                "iam:CreateVirtualMFADevice",
                "iam:EnableMFADevice",
                "iam:ListMFADevices",
                "iam:ListUsers",
                "iam:ListVirtualMFADevices",
                "iam:ResyncMFADevice",
                "iam:ChangePassword",
                "s3:*"
              ],
              "Resource": "*",
              "Sid": "BlockMostAccessUnlessSignedInWithMFA"
            }
          ],
          "Version": "2012-10-17"
        }
      )
}

resource "aws_iam_role" "lambda-assume-role-vpc" {
  name = "iam-role-for-vpc-lambda"

  assume_role_policy = jsonencode(
    {
      Version: "2012-10-17",
      Statement: [
        {
          Action: "sts:AssumeRole",
          Principal: {
            Service: "lambda.amazonaws.com"
          },
          Effect: "Allow",
          Sid: ""
        }
      ]
    }
  )
}

resource "aws_iam_role" "lambda-assume-role-public" {
  name = "iam-role-for-public-lambda"

  assume_role_policy = jsonencode(
    {
      Version: "2012-10-17",
      Statement: [
        {
          Action: "sts:AssumeRole",
          Principal: {
            Service: "lambda.amazonaws.com"
          },
          Effect: "Allow",
          Sid: ""
        }
      ]
    }
  )
}

resource "aws_iam_policy" "lambda-iam-policy-public" {
  name        = "iam-policy-for-public-lambda"
  path        = "/"
  description = "IAM policy for public lambda"

  policy = jsonencode(
    {
      Version: "2012-10-17",
      Statement: [
        {
          Action: [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          Resource: "arn:aws:logs:*:*:*",
          Effect: "Allow"
        }
      ]
    }
  )
}

resource "aws_iam_policy" "lambda-iam-policy-vpc" {
  name        = "iam-policy-for-vpc-lambda"
  path        = "/"
  description = "IAM policy for vpc lambda"

  policy = jsonencode(
    {
      Version: "2012-10-17",
      Statement: [
        {
          Action: [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          Resource: "arn:aws:logs:*:*:*",
          Effect: "Allow"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateNetworkInterface",
                "ec2:DeleteNetworkInterface",
                "ec2:DescribeNetworkInterfaces"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "lambda:InvokeFunction"
            ],
            "Resource": [
                "*"
            ]
        }
      ]
    }
  )
}

resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = false
  allow_users_to_change_password = true
  max_password_age = 90
  password_reuse_prevention = 3
}