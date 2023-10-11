locals {
  local_r53_domain = data.terraform_remote_state.stack.outputs.route53_domain
}

data "terraform_remote_state" "stack" {
  backend = "s3"

  config = {
    bucket  = "uksa-mys-dev-tf-states"
    region  = "eu-west-2"
    key     = "dev-env-structures"
    profile = "uksa-mys-dev-env"
    assume_role = {
      role_arn = "arn:aws:iam::915338536460:role/tf-power-role"
    }
  }
}


data "aws_secretsmanager_secret" "by-name" {
  name = "${var.env_name}-backend"
}