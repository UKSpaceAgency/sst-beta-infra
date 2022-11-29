terraform {
  required_providers {
    cloudfoundry = {
      source  = "cloudfoundry-community/cloudfoundry"
      version = "0.15.5"
    }
  }
}

locals {
  db_name     = "${ var.db_name }-${ var.env_tag }"
  s3_name     = "${ var.s3_name }-${ var.env_tag }"
  logit_name  = "${ var.logit_service_name }-${ var.env_tag }"
}

data "cloudfoundry_service" "db" {
  name = var.db_service
}

data "cloudfoundry_service" "s3" {
  name = var.s3_service
}

resource "cloudfoundry_service_instance" "db" {
  name         = local.db_name
  service_plan = "${data.cloudfoundry_service.db.service_plans["${var.db_plan}"]}"
  json_params  = var.db_extensions
  space        = var.space.id
}

resource "cloudfoundry_service_instance" "aws_s3_bucket" {
  name         = local.s3_name
  service_plan = "${data.cloudfoundry_service.s3.service_plans["default"]}"
  space        = var.space.id
}

resource "cloudfoundry_user_provided_service" "logit" {
  name             = local.logit_name
  space            = var.space.id
  syslog_drain_url = var.logit_service_url
}