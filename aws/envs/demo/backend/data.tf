locals {
  local_r53_domain = data.terraform_remote_state.stack.outputs.route53_domain
}

data "terraform_remote_state" "stack" {
  backend = "s3"

  config = {
    bucket  = "uksa-mys-demo-tf-states"
    region  = "eu-west-2"
    key     = "demo-env-structures"
    profile = "uksa-mys-dev-env"
    assume_role = {
      role_arn = "arn:aws:iam::469816118475:role/tf-power-role"
    }
  }
}


data "aws_secretsmanager_secret" "by-name" {
  name = "${var.env_name}-backend"
}