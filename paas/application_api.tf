resource "cloudfoundry_app" "api" {

  depends_on = [null_resource.api_build_assets]
  name       = var.paas_app_api_name
  space      = data.cloudfoundry_space.space.id
  memory     = var.paas_app_api_memory
  disk_quota = var.pass_app_api_disk_quota
  timeout    = var.paas_app_api_timeout
  instances  = var.paas_app_api_instances
  path       = var.github_fe_api_asset
  command    = var.paas_app_api_command
  strategy   = var.paas_app_api_strategy

  environment = {
    IRON_NAME            = var.paas_app_iron_name
    IRON_PASSWORD        = var.paas_app_iron_password
    API_URL              = format("http://%s.apps.internal:8080/", cloudfoundry_route.app_be_internal.hostname)
  }

  routes {
    route = cloudfoundry_route.api_route_internal.id
  }

  service_binding {
    service_instance = cloudfoundry_service_instance.db.id
  }

  service_binding {
    service_instance = cloudfoundry_user_provided_service.logit.id
  }
}
