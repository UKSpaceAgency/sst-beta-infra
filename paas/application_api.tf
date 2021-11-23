resource "cloudfoundry_app" "api" {
  name       = var.paas_app_api_name
  space      = data.cloudfoundry_space.space.id
  memory     = var.paas_app_api_memory
  disk_quota = var.pass_app_api_disk_quota
  timeout    = var.paas_app_api_timeout
  instances  = var.paas_app_api_instances
  path       = var.github_fe_api_asset
  command    = var.paas_app_api_command

  routes {
    route = cloudfoundry_route.app_route_internal.id
  }

  service_binding {
    service_instance = cloudfoundry_service_instance.db.id
  }
}
