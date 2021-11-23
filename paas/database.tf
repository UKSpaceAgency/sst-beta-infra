resource "cloudfoundry_service_instance" "db" {
  name         = var.paas_db_name
  service_plan = "${data.cloudfoundry_service.db.service_plans["${var.paas_db_plan}"]}"
  space        = "${data.cloudfoundry_space.space.id}"
}
