resource "cloudfoundry_app" "api" {

  provisioner "local-exec" {
    command = "./download-private-release.sh ${var.github_owner} ${var.github_fe_repo} ${var.github_release_tag} ${var.github_fe_api_asset} ./${var.github_fe_api_asset}"

    environment = {
      GIT_TOKEN = var.github_token
    }
  }

  name       = var.paas_app_api_name
  space      = data.cloudfoundry_space.space.id
  memory     = var.paas_app_api_memory
  disk_quota = var.pass_app_api_disk_quota
  timeout    = var.paas_app_api_timeout
  instances  = var.paas_app_api_instances
  path       = var.github_fe_api_asset
  command    = var.paas_app_api_command

  routes {
    route = cloudfoundry_route.api_route_internal.id
  }

  service_binding {
    service_instance = cloudfoundry_service_instance.db.id
  }
}
