resource "cloudfoundry_app" "mp" {

  depends_on = [null_resource.mp_build_assets]
  name       = var.paas_app_mp_name
  space      = data.cloudfoundry_space.space.id
  buildpack  = var.paas_app_mp_buildpack
  path       = var.paas_mp_asset

  service_binding {
    service_instance = cloudfoundry_service_instance.db.id
  }

  service_binding {
    service_instance = cloudfoundry_user_provided_service.logit.id
  }
}
