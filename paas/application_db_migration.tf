resource "cloudfoundry_app" "db_migration" {

  depends_on = [null_resource.be_build_assets]
  name       = var.paas_app_db_migration_name
  space      = data.cloudfoundry_space.space.id
  buildpack  = var.paas_app_be_buildpack
  path       = var.github_be_asset
  command    = var.paas_app_db_migration_command
  health_check_type = "none"

  service_binding {
    service_instance = cloudfoundry_service_instance.db.id
  }

  service_binding {
    service_instance = cloudfoundry_user_provided_service.logit.id
  }
}
