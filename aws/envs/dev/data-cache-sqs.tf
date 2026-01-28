module "data-cache-sqs" {
  source     = "../../tf-modules/data-cache-sqs"
  env_name   = var.env_name

  data-cache-sns-topic-arn     = "arn:aws:sns:eu-west-2:744996504263:data-cache-prod"
  sqs_retention_seconds          = 3600*24*14 //14days
  sqs_visibility_timeout_seconds = 900 #15*60s = 900s = 15min
}