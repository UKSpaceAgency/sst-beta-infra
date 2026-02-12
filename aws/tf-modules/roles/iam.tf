data "aws_iam_policy" "secrets-manager" {
  name = "SecretsManagerReadWrite"
}

data "aws_iam_policy" "s3-full-access" {
  name = "AmazonS3FullAccess"
}

data "aws_iam_policy" "sqs-full-access" {
  name = "AmazonSQSFullAccess"
}

data "aws_iam_policy" "dynamo-full-access" {
  name = "AmazonDynamoDBFullAccess_v2"
}

resource "aws_iam_policy" "access-secrets-from-ecs" {
  name = "access-secrets-from-ecs"
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
  name = "allow_ecs_command_execution"
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

  assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Sid    = ""
          Principal = {
            Service = "ecs-tasks.amazonaws.com"
          }
        },
      ]
    })

}

resource "aws_iam_role_policy_attachment" "ecs_task_role_secret_manager" {
  role       = aws_iam_role.ecs-task-role.name
  policy_arn = data.aws_iam_policy.secrets-manager.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_s3_full" {
  role       = aws_iam_role.ecs-task-role.name
  policy_arn = data.aws_iam_policy.s3-full-access.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_ecs_exec" {
  role       = aws_iam_role.ecs-task-role.name
  policy_arn = aws_iam_policy.allow_ecs_command_execution.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_sqs" {
  role       = aws_iam_role.ecs-task-role.name
  policy_arn = data.aws_iam_policy.sqs-full-access.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_dynamo" {
  role       = aws_iam_role.ecs-task-role.name
  policy_arn = data.aws_iam_policy.dynamo-full-access.arn
}



data "aws_iam_policy" "ecs-task-exec" {
  name = "AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy" "ec2-service-role" {
  name = "AmazonEC2ContainerServiceRole"
}

resource "aws_iam_role" "ecs-execution-role" {
  name = "ecs-execution-role-for-${var.env_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_task_exec" {
  role       = aws_iam_role.ecs-execution-role.name
  policy_arn = data.aws_iam_policy.ecs-task-exec.arn
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_ec2_service" {
  role       = aws_iam_role.ecs-execution-role.name
  policy_arn = data.aws_iam_policy.ec2-service-role.arn
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_secrets" {
  role       = aws_iam_role.ecs-execution-role.name
  policy_arn = aws_iam_policy.access-secrets-from-ecs.arn
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
  name = "ecs_events_role-for-${var.env_name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_events.json
}

resource "aws_iam_role_policy_attachment" "ecs_events_task_exec" {
  role       = aws_iam_role.ecs_events.name
  policy_arn = data.aws_iam_policy.ecs-task-exec.arn
}

resource "aws_iam_role_policy_attachment" "ecs_events_ec2_service" {
  role       = aws_iam_role.ecs_events.name
  policy_arn = data.aws_iam_policy.ec2-service-role.arn
}

resource "aws_iam_role_policy_attachment" "ecs_events_secrets" {
  role       = aws_iam_role.ecs_events.name
  policy_arn = aws_iam_policy.access-secrets-from-ecs.arn
}

resource "aws_iam_policy" "developers_policy" {
  name        = "developers-policy-limited-mfa"
  description = "Developer accesspolicy"

  policy = jsonencode(
    {
      "Statement" : [
        {
            "Sid": "QueryEditor1",
            "Effect": "Allow",
            "Action": [
                "tag:GetResources",
                "dbqms:CreateFavoriteQuery",
                "dbqms:DescribeFavoriteQueries",
                "dbqms:UpdateFavoriteQuery",
                "dbqms:DeleteFavoriteQueries",
                "dbqms:GetQueryString",
                "dbqms:CreateQueryHistory",
                "dbqms:UpdateQueryHistory",
                "dbqms:DeleteQueryHistory",
                "dbqms:DescribeQueryHistory",
                "rds-data:BatchExecuteStatement",
                "rds-data:BeginTransaction",
                "rds-data:CommitTransaction",
                "rds-data:ExecuteStatement",
                "rds-data:RollbackTransaction",
                "rds:Describe*"
            ],
            "Resource": "*",
            "Condition" : {
            "Bool" : {
              "aws:MultiFactorAuthPresent" : "true"
            }
          },
        },
        {
          "Action" : [
            "s3:*"
          ],
          "Effect" : "Allow",
          "Resource" : "*",
          "Sid" : "s3fullAccess"
        },
        {
          "Action" : [
            "secretsmanager:Get*",
            "secretsmanager:List*",
            "secretsmanager:Describe*"
          ],
          "Condition" : {
            "Bool" : {
              "aws:MultiFactorAuthPresent" : "true"
            }
          },
          "Effect" : "Allow",
          "Resource" : "*",
          "Sid" : "SecretManagerViewOnly"
        },
        {
          "Action" : [
            "logs:GetLogEvents",
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams",
            "logs:TestMetricFilter",
            "logs:DescribeMetricFilters",
            "logs:ListTagsForResource",
            "logs:ListAnomalies",
            "logs:Filter*",
            "logs:StartQuery",
            "logs:StopQuery",
            "logs:DescribeQueries",
            "logs:GetLogGroupFields",
            "logs:GetLogRecord",
            "logs:GetQueryResults",
            "logs:PutMetricFilter",
            "cloudwatch:Describe*",
            "cloudwatch:Get*",
            "cloudwatch:List*"
          ],
          "Condition" : {
            "Bool" : {
              "aws:MultiFactorAuthPresent" : "true"
            }
          },
          "Effect" : "Allow",
          "Resource" : "*",
          "Sid" : "CloudwatchReadOnly"
        },
        {
          "Action" : [
            "ecs:Get*",
            "ecs:Describe*",
            "ecs:List*"
          ],
          "Condition" : {
            "Bool" : {
              "aws:MultiFactorAuthPresent" : "true"
            }
          },
          "Effect" : "Allow",
          "Resource" : "*",
          "Sid" : "EcsReadOnly"
        },
        {
          "Action" : [
            "iam:ChangePassword"
          ],
          "Effect" : "Allow",
          "Resource" : [
            "arn:aws:iam::*:user/$${aws:username}"
          ],
          "Sid" : "IAMChangePassword"
        },
        {
          "Action" : [
            "iam:GetAccountPasswordPolicy"
          ],
          "Effect" : "Allow",
          "Resource" : "*",
          "Sid" : "GetPasswordPolicy"
        },
        {
          "Action" : [
            "iam:ListUsers",
            "iam:ListVirtualMFADevices"
          ],
          "Effect" : "Allow",
          "Resource" : "*",
          "Sid" : "AllowListActions"
        },
        {
          "Action" : [
            "iam:CreateAccessKey",
            "iam:DeleteAccessKey",
            "iam:ListAccessKeys",
            "iam:UpdateAccessKey"
          ],
          "Condition" : {
            "Bool" : {
              "aws:MultiFactorAuthPresent" : "true"
            }
          },
          "Effect" : "Allow",
          "Resource" : "arn:aws:iam::*:user/$${aws:username}",
          "Sid" : "AllowManageOwnAccessKeys"
        },
        {
          "Action" : [
            "iam:DeleteSSHPublicKey",
            "iam:GetSSHPublicKey",
            "iam:ListSSHPublicKeys",
            "iam:UpdateSSHPublicKey",
            "iam:UploadSSHPublicKey"
          ],
          "Condition" : {
            "Bool" : {
              "aws:MultiFactorAuthPresent" : "true"
            }
          },
          "Effect" : "Allow",
          "Resource" : "arn:aws:iam::*:user/$${aws:username}",
          "Sid" : "AllowManageOwnSSHPublicKeys"
        },
        {
          "Action" : [
            "iam:ListMFADevices"
          ],
          "Effect" : "Allow",
          "Resource" : [
            "arn:aws:iam::*:mfa/*",
            "arn:aws:iam::*:user/$${aws:username}"
          ],
          "Sid" : "AllowIndividualUserToListOnlyTheirOwnMFA"
        },
        {
          "Action" : [
            "iam:CreateVirtualMFADevice",
            "iam:DeleteVirtualMFADevice",
            "iam:EnableMFADevice",
            "iam:ResyncMFADevice"
          ],
          "Effect" : "Allow",
          "Resource" : [
            "arn:aws:iam::*:mfa/*",
            "arn:aws:iam::*:user/$${aws:username}"
          ],
          "Sid" : "AllowIndividualUserToManageTheirOwnMFA"
        },
        {
          "Action" : [
            "iam:DeactivateMFADevice"
          ],
          "Condition" : {
            "Bool" : {
              "aws:MultiFactorAuthPresent" : "true"
            }
          },
          "Effect" : "Allow",
          "Resource" : [
            "arn:aws:iam::*:mfa/*",
            "arn:aws:iam::*:user/$${aws:username}"
          ],
          "Sid" : "AllowIndividualUserToDeactivateOnlyTheirOwnMFAOnlyWhenUsingMFA"
        },
        {
          "Condition" : {
            "BoolIfExists" : {
              "aws:MultiFactorAuthPresent" : "false"
            }
          },
          "Effect" : "Deny",
          "NotAction" : [
            "iam:CreateVirtualMFADevice",
            "iam:EnableMFADevice",
            "iam:ListMFADevices",
            "iam:ListUsers",
            "iam:ListVirtualMFADevices",
            "iam:ResyncMFADevice",
            "iam:ChangePassword",
            "s3:*",
            "dynamodb:*"
          ],
          "Resource" : "*",
          "Sid" : "BlockMostAccessUnlessSignedInWithMFA"
        }
      ],
      "Version" : "2012-10-17"
    }
  )
}

resource "aws_iam_policy" "billing_mfa_policy" {
  name        = "billing-policy-limited-mfa"
  description = "Billing job function plus MFA policy"

  policy = jsonencode(
    {
      "Statement" : [
        {
          "Action" : [
            "account:GetAccountInformation",
            "aws-portal:*Billing",
            "aws-portal:*PaymentMethods",
            "aws-portal:*Usage",
            "billing:GetBillingData",
            "billing:GetBillingDetails",
            "billing:GetBillingNotifications",
            "billing:GetBillingPreferences",
            "billing:GetContractInformation",
            "billing:GetCredits",
            "billing:GetIAMAccessPreference",
            "billing:GetSellerOfRecord",
            "billing:ListBillingViews",
            "billing:PutContractInformation",
            "billing:RedeemCredits",
            "billing:UpdateBillingPreferences",
            "billing:UpdateIAMAccessPreference",
            "budgets:ModifyBudget",
            "budgets:ViewBudget",
            "ce:CreateNotificationSubscription",
            "ce:CreateReport",
            "ce:DeleteNotificationSubscription",
            "ce:DeleteReport",
            "ce:ListCostAllocationTags",
            "ce:UpdateCostAllocationTagsStatus",
            "ce:UpdateNotificationSubscription",
            "ce:UpdatePreferences",
            "ce:UpdateReport",
            "consolidatedbilling:GetAccountBillingRole",
            "consolidatedbilling:ListLinkedAccounts",
            "cur:DeleteReportDefinition",
            "cur:DescribeReportDefinitions",
            "cur:GetClassicReport",
            "cur:GetClassicReportPreferences",
            "cur:GetUsageReport",
            "cur:ModifyReportDefinition",
            "cur:PutClassicReportPreferences",
            "cur:PutReportDefinition",
            "cur:ValidateReportDestination",
            "freetier:GetFreeTierAlertPreference",
            "freetier:GetFreeTierUsage",
            "freetier:PutFreeTierAlertPreference",
            "invoicing:GetInvoiceEmailDeliveryPreferences",
            "invoicing:GetInvoicePDF",
            "invoicing:ListInvoiceSummaries",
            "invoicing:PutInvoiceEmailDeliveryPreferences",
            "payments:CreatePaymentInstrument",
            "payments:DeletePaymentInstrument",
            "payments:GetPaymentInstrument",
            "payments:GetPaymentStatus",
            "payments:ListPaymentPreferences",
            "payments:MakePayment",
            "payments:UpdatePaymentPreferences",
            "purchase-orders:AddPurchaseOrder",
            "purchase-orders:DeletePurchaseOrder",
            "purchase-orders:GetPurchaseOrder",
            "purchase-orders:ListPurchaseOrderInvoices",
            "purchase-orders:ListPurchaseOrders",
            "purchase-orders:ListTagsForResource",
            "purchase-orders:ModifyPurchaseOrders",
            "purchase-orders:TagResource",
            "purchase-orders:UntagResource",
            "purchase-orders:UpdatePurchaseOrder",
            "purchase-orders:UpdatePurchaseOrderStatus",
            "purchase-orders:ViewPurchaseOrders",
            "tax:BatchPutTaxRegistration",
            "tax:DeleteTaxRegistration",
            "tax:GetExemptions",
            "tax:GetTaxInheritance",
            "tax:GetTaxInterview",
            "tax:GetTaxRegistration",
            "tax:GetTaxRegistrationDocument",
            "tax:ListTaxRegistrations",
            "tax:PutTaxInheritance",
            "tax:PutTaxInterview",
            "tax:PutTaxRegistration",
            "tax:UpdateExemptions"
          ],
          "Condition" : {
            "Bool" : {
              "aws:MultiFactorAuthPresent" : "true"
            }
          },
          "Effect" : "Allow",
          "Resource" : "*",
          "Sid" : "BillingPlusMFA"
        },
        {
          "Action" : [
            "iam:ChangePassword"
          ],
          "Effect" : "Allow",
          "Resource" : [
            "arn:aws:iam::*:user/$${aws:username}"
          ],
          "Sid" : "IAMChangePassword"
        },
        {
          "Action" : [
            "iam:GetAccountPasswordPolicy"
          ],
          "Effect" : "Allow",
          "Resource" : "*",
          "Sid" : "GetPasswordPolicy"
        },
        {
          "Action" : [
            "iam:ListUsers",
            "iam:ListVirtualMFADevices"
          ],
          "Effect" : "Allow",
          "Resource" : "*",
          "Sid" : "AllowListActions"
        },
        {
          "Action" : [
            "iam:ListMFADevices"
          ],
          "Effect" : "Allow",
          "Resource" : [
            "arn:aws:iam::*:mfa/*",
            "arn:aws:iam::*:user/$${aws:username}"
          ],
          "Sid" : "AllowIndividualUserToListOnlyTheirOwnMFA"
        },
        {
          "Action" : [
            "iam:CreateVirtualMFADevice",
            "iam:DeleteVirtualMFADevice",
            "iam:EnableMFADevice",
            "iam:ResyncMFADevice"
          ],
          "Effect" : "Allow",
          "Resource" : [
            "arn:aws:iam::*:mfa/*",
            "arn:aws:iam::*:user/$${aws:username}"
          ],
          "Sid" : "AllowIndividualUserToManageTheirOwnMFA"
        },
        {
          "Action" : [
            "iam:DeactivateMFADevice"
          ],
          "Condition" : {
            "Bool" : {
              "aws:MultiFactorAuthPresent" : "true"
            }
          },
          "Effect" : "Allow",
          "Resource" : [
            "arn:aws:iam::*:mfa/*",
            "arn:aws:iam::*:user/$${aws:username}"
          ],
          "Sid" : "AllowIndividualUserToDeactivateOnlyTheirOwnMFAOnlyWhenUsingMFA"
        },
        {
          "Condition" : {
            "BoolIfExists" : {
              "aws:MultiFactorAuthPresent" : "false"
            }
          },
          "Effect" : "Deny",
          "NotAction" : [
            "iam:CreateVirtualMFADevice",
            "iam:EnableMFADevice",
            "iam:ListMFADevices",
            "iam:ListUsers",
            "iam:ListVirtualMFADevices",
            "iam:ResyncMFADevice",
            "iam:ChangePassword"
          ],
          "Resource" : "*",
          "Sid" : "BlockMostAccessUnlessSignedInWithMFA"
        }
      ],
      "Version" : "2012-10-17"
    }
  )
}

resource "aws_iam_role" "lambda-assume-role-vpc" {
  name = "iam-role-for-vpc-lambda"

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

resource "aws_iam_role" "lambda-assume-role-public" {
  name = "iam-role-for-public-lambda"

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

resource "aws_iam_policy" "lambda-iam-policy-public" {
  name        = "iam-policy-for-public-lambda"
  path        = "/"
  description = "IAM policy for public lambda"

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
          "Effect" : "Allow",
          "Action" : [
            "ec2:CreateNetworkInterface",
            "ec2:DeleteNetworkInterface",
            "ec2:DescribeNetworkInterfaces"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "secretsmanager:GetSecretValue"
          ],
          "Resource" : [
            "*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "lambda:InvokeFunction"
          ],
          "Resource" : [
            "*"
          ]
        }
      ]
    }
  )
}

resource "aws_iam_role" "state_machine_role" {
  name = "iam-role-for-state-machine"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "states.amazonaws.com"
          },
          "Action" : "sts:AssumeRole"
        }
      ]
    }
  )
}

resource "aws_iam_policy" "state_machine_iam_policy" {
  name        = "iam-policy-for-state_machine"
  path        = "/"
  description = "IAM policy for state machine"

  policy = jsonencode(
    {
      Version : "2012-10-17",
      Statement : [
        {
          Action : [
            "logs:CreateLogDelivery",
            "logs:CreateLogStream",
            "logs:GetLogDelivery",
            "logs:UpdateLogDelivery",
            "logs:DeleteLogDelivery",
            "logs:ListLogDeliveries",
            "logs:PutLogEvents",
            "logs:PutResourcePolicy",
            "logs:DescribeResourcePolicies",
            "logs:DescribeLogGroups"
          ],
          "Resource" : [
            "*"
          ]
          Effect : "Allow"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "lambda:InvokeFunction"
          ],
          "Resource" : [
            "*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "cloudwatch:DescribeAlarms"
          ]
          "Resource" : [
            "*"
          ]
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "state_machine_policy_attachment" {
  role       = aws_iam_role.state_machine_role.name
  policy_arn = aws_iam_policy.state_machine_iam_policy.arn
}

resource "aws_iam_role" "event_bridge_invoke_sfn_iam_role" {
  name = "iam-role-for-event-bridge-invoke"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "events.amazonaws.com"
          },
          "Action" : "sts:AssumeRole"
        }
      ]
    }
  )
}

data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "event_bridge_invoke_sfn_iam_policy" {
  name        = "iam-policy-for-event-bridge_invoke"
  path        = "/"
  description = "IAM policy for event bridge"

  policy = jsonencode(
    {
      Version : "2012-10-17",
      Statement : [
        {
          "Effect" : "Allow",
          "Action" : [
            "states:StartExecution"
          ],
          "Resource" : [
            "arn:aws:states:eu-west-2:${data.aws_caller_identity.current.account_id}:stateMachine:*"
          ]
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "event_bridge_policy_attachment" {
  role       = aws_iam_role.event_bridge_invoke_sfn_iam_role.name
  policy_arn = aws_iam_policy.event_bridge_invoke_sfn_iam_policy.arn
}

resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = false
  allow_users_to_change_password = true
  max_password_age               = 90
  password_reuse_prevention      = 3
}

#--- guard duty role
resource "aws_iam_role" "malware_s3_protection_role" {
  name = "iam-role-for-guard_duty"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "malware-protection-plan.guardduty.amazonaws.com"
          },
          "Action" : "sts:AssumeRole"
        }
      ]
    }
  )
}

resource "aws_iam_policy" "malware_s3_protection_iam_policy" {
  name        = "iam-policy-for-malware-s3-protection"
  path        = "/"
  description = "IAM policy for GuardDuty's malware protection"

  policy = jsonencode(
    {
    "Version": "2012-10-17",
    "Statement": [{
            "Sid": "AllowManagedRuleToSendS3EventsToGuardDuty",
            "Effect": "Allow",
            "Action": [
                "events:PutRule",
                "events:DeleteRule",
                "events:PutTargets",
                "events:RemoveTargets"
            ],
            "Resource": [
                "arn:aws:events:eu-west-2:${data.aws_caller_identity.current.account_id}:rule/DO-NOT-DELETE-AmazonGuardDutyMalwareProtectionS3*"
            ],
            "Condition": {
                "StringLike": {
                    "events:ManagedBy": "malware-protection-plan.guardduty.amazonaws.com"
                }
            }
        },
        {
            "Sid": "AllowGuardDutyToMonitorEventBridgeManagedRule",
            "Effect": "Allow",
            "Action": [
                "events:DescribeRule",
                "events:ListTargetsByRule"
            ],
            "Resource": [
                "arn:aws:events:eu-west-2:${data.aws_caller_identity.current.account_id}:rule/DO-NOT-DELETE-AmazonGuardDutyMalwareProtectionS3*"
            ]
        },
        {
            "Sid": "AllowPostScanTag",
            "Effect": "Allow",
            "Action": [
                "s3:PutObjectTagging",
                "s3:GetObjectTagging",
                "s3:PutObjectVersionTagging",
                "s3:GetObjectVersionTagging"
            ],
            "Resource": [
                "arn:aws:s3:::*"
            ]
        },
        {
            "Sid": "AllowEnableS3EventBridgeEvents",
            "Effect": "Allow",
            "Action": [
                "s3:PutBucketNotification",
                "s3:GetBucketNotification"
            ],
            "Resource": [
                "arn:aws:s3:::*"
            ]
        },
        {
            "Sid": "AllowPutValidationObject",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::*/malware-protection-resource-validation-object"
            ]
        },
        {
            "Sid": "AllowCheckBucketOwnership",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::*"
            ]
        },
        {
           "Sid": "AllowMalwareScan",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:GetObjectVersion"
            ],
            "Resource": [
                "arn:aws:s3:::*"
            ]
        }
    ]
}
  )
}

resource "aws_iam_role_policy_attachment" "guard_duty_policy_attachment" {
  role       = aws_iam_role.malware_s3_protection_role.name
  policy_arn = aws_iam_policy.malware_s3_protection_iam_policy.arn
}