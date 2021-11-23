data "cloudfoundry_service" "db" {
  name = var.paas_db_service
}

data "cloudfoundry_service" "s3" {
  name = var.paas_s3_service
}
