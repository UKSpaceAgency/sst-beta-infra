resource "cloudfoundry_app" "fe" {

  provisioner "local-exec" {
    command = "./download-private-release.sh ${var.github_owner} ${var.github_fe_repo} ${var.github_release_tag} ${var.github_fe_sst_asset} ./${var.github_fe_sst_asset}"

    environment = {
      GIT_TOKEN = var.github_token
    }
  }

  provisioner "local-exec" {
    command =  "echo 'location /api { proxy_pass http://${var.paas_app_api_route_name}.apps.internal:8080/graphql; }' > ${var.paas_app_fe_proxy_conf}"
  }

  provisioner "local-exec" {
    command = "zip ${var.github_fe_sst_asset} ${var.paas_app_fe_proxy_conf}"
  }

  depends_on = [cloudfoundry_app.api]
  name        = var.paas_app_fe_name
  space       = data.cloudfoundry_space.space.id
  buildpack   = var.paas_app_fe_buildpack
  memory      = var.paas_app_fe_memory
  disk_quota  = var.paas_app_fe_disk_quota
  instances   = var.paas_app_fe_instances
  path        = var.github_fe_sst_asset

  environment = {
    "PRIVATE_API_URL" = format("http://%s.apps.internal:8080", cloudfoundry_route.api_route_internal.hostname)
  }

  routes {
    route = cloudfoundry_route.app_route_cloud.id
  }

}
