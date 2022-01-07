resource "cloudfoundry_app" "db_migration" {

  depends_on = [null_resource.mp_build_assets]
  name       = var.paas_app_mp_name
  space      = data.cloudfoundry_space.space.id
  buildpack  = var.paas_app_mp_buildpack
  path       = var.paas_mp_asset

  dynamic "routes" {
    for_each = var.paas_custom_domain_flag? [] : [1]
    content {
      route = cloudfoundry_route.app_route_cloud.id
    }
  }

  dynamic "routes" {
    for_each = var.paas_custom_domain_flag? [1] : []
    content {
      route = cloudfoundry_route.app_route_custom_domain[0].id
    }
  }

  service_binding {
    service_instance = cloudfoundry_service_instance.db.id
  }

  service_binding {
    service_instance = cloudfoundry_user_provided_service.logit.id
  }
}
