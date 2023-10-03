#data "aws_secretsmanager_secret" "by-name" {
#  name = "${var.env_name}-backend"
#}
#
#data "aws_secretsmanager_secret_version" "current" {
#  secret_id = data.aws_secretsmanager_secret.by-name.id
#}
#
#module "alarm_lambda_slack" {
#  source                 = "../../tf-modules/lambda_in_public"
#  env_name               = var.env_name
#  lambda_function_name   = "slack-notifier-${var.env_name}"
#  lambda_handler_name    = "main.lambda_handler"
#  lambda_policy_arn      = module.iam.lambda_iam_policy_public_arn
#  lambda_role_arn        = module.iam.lambda_public_iam_role_arn
#  lambda_role_name       = module.iam.lambda_public_iam_role_name
#  lambda_filename = "../../alarm-lambda-notif/python-package.zip"
#
#  env_vars = {
#        "SLACK_WEBHOOK_URL"  = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["notifiersWebhookUrl"]
#  }
#}
#
#
#module "alarm_lambda_vpc" {
#  source                 = "../../tf-modules/lambda_in_vpc"
#  env_name               = var.env_name
#  vpc_security_group_ids = [module.network.ssh-security-group-id]
#  private_subnet_ids       = module.network.private_subnet_ids
#  lambda_function_name   = "injection-check-${var.env_name}"
#  lambda_handler_name    = "main.lambda_handler"
#  lambda_policy_arn      = module.iam.lambda_iam_policy_vpc_arn
#  lambda_role_arn        = module.iam.lambda_vpc_iam_role_arn
#  lambda_role_name       = module.iam.lambda_vpc_iam_role_name
#  lambda_filename = "../../alarms-lambda/python-package.zip"
#
#  env_vars = {
#        "SLACK_LAMBDA_ARN"  = module.alarm_lambda_slack.public_lambda_arn
#        "SECRET_NAME" = "${var.env_name}-backend"
#        "TIMEOUT_MINUTES" = "150"
#        "ENV_NAME" = var.env_name
#        "vpc_endpoint_lambda" = module.network.vpc_lambda_endpoint_arn
#        "vpc_endpoint_secrets" = module.network.vpc_secrets_manager_endpoint_arn
#  }
#}
#
##----- scheduling every 15min
#resource "aws_cloudwatch_event_rule" "event_rule" {
#  name        = "rule-for-alarms-lambda"
#  description = "Invoke Lambda every 15 minutes"
#  schedule_expression = "rate(15 minutes)"
#}
#
#resource "aws_cloudwatch_event_target" "event_target" {
#  rule      = aws_cloudwatch_event_rule.event_rule.name
#  target_id = "invoke-lambda"
#  arn = module.alarm_lambda_vpc.vpc_lambda_arn
#}
#
#resource "aws_lambda_permission" "allow_cloudwatch" {
#  statement_id  = "AllowExecutionFromCloudWatch"
#  action        = "lambda:InvokeFunction"
#  function_name = module.alarm_lambda_vpc.vpc_lambda_name
#  principal     = "events.amazonaws.com"
#  source_arn    = aws_cloudwatch_event_rule.event_rule.arn
#}