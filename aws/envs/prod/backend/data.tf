locals {
  local_r53_domain = data.terraform_remote_state.stack.outputs.route53_domain
}

data "terraform_remote_state" "stack" {
  backend = "s3"

  config = {
    bucket  = "uksa-mys-prod-tf-states"
    region  = "eu-west-2"
    key     = "prod-env-structures"
    profile  = "uksa-mys-dev-env"
  }
}


data "aws_secretsmanager_secret" "by-name" {
  name = "${var.env_name}-backend"
}