# Bucket need to be created manually
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    encrypt  = true
    bucket   = "uksa-mys-dev-tf-states"
    region   = "eu-west-2"
    key      = "dev-env-structures.frontend"
    profile  = "uksa-mys-dev-env"
    role_arn = "arn:aws:iam::915338536460:role/tf-power-role"
  }
}

provider "aws" {
  region  = "eu-west-2"
  profile = "uksa-mys-dev-env"
  assume_role {
    role_arn = "arn:aws:iam::915338536460:role/tf-power-role"
  }
  default_tags {
    tags = {
      Environment = var.env_name
      Owner       = "UKSA"
      Project     = "MyS"
    }
  }
}

