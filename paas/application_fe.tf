resource "cloudfoundry_app" "fe" {

  depends_on = [null_resource.fe_build_assets]
  name        = var.paas_app_fe_name
  space       = data.cloudfoundry_space.space.id
  buildpack   = var.paas_app_fe_buildpack
  memory      = var.paas_app_fe_memory
  disk_quota  = var.paas_app_fe_disk_quota
  instances   = var.paas_app_fe_instances
  path        = var.github_fe_app_asset
  command     = var.paas_app_fe_command

  environment = {
    IRON_NAME               = var.paas_app_iron_name
    IRON_PASSWORD           = var.paas_app_iron_password
    PAGES_LOCATION          = "./.next/server/pages"
    GRAPHQL_URL             = "http://${cloudfoundry_route.api_route_internal.hostname}.${data.cloudfoundry_domain.internal.name}:8080/graphql"
    BASE_API_URL            = ${ var.paas_custom_domain_flag == false ? "https://${cloudfoundry_route.app_route_cloud.hostname}.${data.cloudfoundry_domain.cloudapps.name}/api" : "https://${var.paas_custom_subdomain}.${data.cloudfoundry_domain.custom.name}/api"}
  }

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
    service_instance = cloudfoundry_user_provided_service.logit.id
  }

}
