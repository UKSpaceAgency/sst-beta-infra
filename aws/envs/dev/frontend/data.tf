data "terraform_remote_state" "stack" {
  backend = "s3"

  config = {
    bucket  = "mys-dev-tf-states"
    region  = "eu-west-2"
    key     = "dev-env-structures"
    profile = "mys-dev-env"
  }
}


data "aws_secretsmanager_secret" "by-name" {
  name = "${var.env_name}-backend"
}