resource "cloudfoundry_app" "fe" {
  name       = var.paas_app_fe_name
  space      = data.cloudfoundry_space.space.id
  buildpack  = var.paas_app_fe_buildpack
  memory     = var.paas_app_fe_memory
  disk_quota = var.paas_app_fe_disk_quota
  instances  = var.paas_app_fe_instances
  path       = var.github_fe_sst_asset

  routes {
    route = cloudfoundry_route.app_route_cloud.id
  }

  routes {
    route = cloudfoundry_route.app_route_internal.id
  }
}
