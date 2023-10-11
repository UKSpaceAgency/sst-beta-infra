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
    encrypt = true
    bucket  = "uksa-mys-prod-tf-states"
    region  = "eu-west-2"
    key     = "prod-env-structures"
    profile = "uksa-mys-dev-env"
  }
}

provider "aws" {
  region  = "eu-west-2"
  profile = "uksa-mys-dev-env"
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
  default_tags {
    tags = {
      Environment = var.env_name
      Owner       = "UKSA"
      Project     = "MyS"
    }
  }
}
