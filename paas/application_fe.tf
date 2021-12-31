resource "cloudfoundry_app" "fe" {

  depends_on = [null_resource.fe_build_assets,cloudfoundry_app.api]
  name        = var.paas_app_fe_name
  space       = data.cloudfoundry_space.space.id
  buildpack   = var.paas_app_fe_buildpack
  memory      = var.paas_app_fe_memory
  disk_quota  = var.paas_app_fe_disk_quota
  instances   = var.paas_app_fe_instances
  path        = var.github_fe_app_asset

  environment = {
    "PRIVATE_API_URL" = format("http://%s.apps.internal:8080/graphql/", cloudfoundry_route.api_route_internal.hostname)
  }

  routes {
    route = cloudfoundry_route.app_route_cloud.id
  }

  routes {
    route = cloudfoundry_route.app_route_custom_domain.id
  }

  service_binding {
    service_instance = cloudfoundry_user_provided_service.logit.id
  }

}
