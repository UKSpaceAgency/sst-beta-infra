data "aws_region" "this" {}

data "aws_caller_identity" "this" {}

locals {
  account_id       = data.aws_caller_identity.this.account_id
  region           = data.aws_region.this.name
  ses_identity_arn = "arn:aws:ses:${local.region}:${local.account_id}:identity/${var.route53_domain}"
  retention        = 0
}

resource "aws_iam_user" "mail" {
  name = "auth0_smtp_user"
}

resource "aws_iam_user_policy_attachment" "send_mail" {
  policy_arn = aws_iam_policy.send_mail.arn
  user       = aws_iam_user.mail.name
}

resource "aws_iam_policy" "send_mail" {
  name   = "auth0-send-mail"
  policy = data.aws_iam_policy_document.send_mail.json
}

data "aws_iam_policy_document" "send_mail" {
  statement {
    actions   = ["ses:SendRawEmail"]
    resources = [local.ses_identity_arn]
  }
}

resource "aws_iam_access_key" "mail_user_access_key" {
  user = aws_iam_user.mail.name
}

resource "aws_secretsmanager_secret_version" "iam_user_credentials" {
  secret_id = aws_secretsmanager_secret.mail-secrets.id
  secret_string = jsonencode({
    access_key = aws_iam_access_key.mail_user_access_key.id
    secret_key = aws_iam_access_key.mail_user_access_key.secret
  })
}


resource "aws_secretsmanager_secret" "mail-secrets" {
  name                    = "${var.env_name}-auth0-mail"
  recovery_window_in_days = local.retention
}