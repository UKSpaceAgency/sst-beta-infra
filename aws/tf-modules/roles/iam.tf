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

resource "aws_iam_role" "ecs-task-role" {
  name = "ecs-task-role-for-${var.env_name}"

  managed_policy_arns = [data.aws_iam_policy.secrets-manager.arn, data.aws_iam_policy.s3-full-access.arn]
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