# Bucket need to be created manually
terraform {
  required_version = ">= 1.4.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    encrypt = true
    bucket  = "mys-dev-tf-states"
    region  = "eu-west-2"
    key     = "dev-env-structures"
    profile = "mys-dev-env"
  }
}

provider "aws" {
  region  = "eu-west-2"
  profile = "mys-dev-env"
  default_tags {
    tags = {
      Environment = var.env_name
      Owner       = "thePSC"
      Project     = "MyS"
    }
  }
}
