terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    auth0 = {
      source  = "auth0/auth0"
      version = "~> 0.48.0"
    }
  }

  backend "s3" {
    encrypt  = true
    bucket   = "uksa-mys-demo-tf-states"
    region   = "eu-west-2"
    key      = "demo-env-structures"
    profile  = "uksa-mys-dev-env"
    assume_role  = {
      role_arn = "arn:aws:iam::469816118475:role/tf-power-role"
    }
  }
}

provider "aws" {
  region  = "eu-west-2"
  profile = "uksa-mys-dev-env"
  assume_role {
    role_arn = "arn:aws:iam::469816118475:role/tf-power-role"
  }
  default_tags {
    tags = {
      Environment = var.env_name
      Owner       = "UKSA"
      Project     = "MyS"
    }
  }
}

provider "aws" {
  alias   = "useast1"
  region  = "us-east-1"
  profile = "uksa-mys-dev-env"
  assume_role {
    role_arn = "arn:aws:iam::469816118475:role/tf-power-role"
  }
  default_tags {
    tags = {
      Environment = var.env_name
      Owner       = "UKSA"
      Project     = "MyS"
    }
  }
}
