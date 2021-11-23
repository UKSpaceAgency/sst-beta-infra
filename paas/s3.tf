resource "cloudfoundry_service_instance" "aws_s3_bucket" {
  name         = var.paas_s3_name
  service_plan = "${data.cloudfoundry_service.s3.service_plans["default"]}"
  space        = "${data.cloudfoundry_space.space.id}"
}