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
    encrypt = true
    bucket  = "uksa-mys-prod-tf-states"
    region  = "eu-west-2"
    key     = "prod-env-structures.data-cache"
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

