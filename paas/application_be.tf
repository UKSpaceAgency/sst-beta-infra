resource "cloudfoundry_app" "be" {

  provisioner "local-exec" {
    command = "./download-private-release.sh ${var.github_thepsc} ${var.github_be_repo} ${var.github_release_tag} ${var.github_be_asset} ./${var.github_be_asset}"

    environment = {
      GIT_TOKEN = var.github_token
    }
  }

  provisioner "local-exec" {
    command = "echo ./download-private-release.sh ${var.github_thepsc} ${var.github_be_repo} ${var.github_release_tag} ${var.github_be_asset} ./${var.github_be_asset}"
  }

  name       = var.paas_app_be_name
  space      = data.cloudfoundry_space.space.id
  buildpack  = var.paas_app_be_buildpack
  memory     = var.paas_app_be_memory
  disk_quota = var.pass_app_be_disk_quota
  timeout    = var.paas_app_be_timeout
  instances  = var.paas_app_be_instances
  path       = var.github_be_asset
  command    = var.paas_app_be_command

  routes {
    route = cloudfoundry_route.app_be_internal.id
  }

  service_binding {
    service_instance = cloudfoundry_service_instance.db.id
  }

  service_binding {
    service_instance = cloudfoundry_service_instance.aws_s3_bucket.id
  }
}