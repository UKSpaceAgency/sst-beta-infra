resource "cloudfoundry_app" "be" {

  depends_on = [null_resource.be_build_assets]
  name       = var.paas_app_be_name
  space      = data.cloudfoundry_space.space.id
  buildpack  = var.paas_app_be_buildpack
  memory     = var.paas_app_be_memory
  disk_quota = var.pass_app_be_disk_quota
  timeout    = var.paas_app_be_timeout
  instances  = var.paas_app_be_instances
  path       = var.github_be_asset
  command    = var.paas_app_be_command

  environment = {
    SPACE_TRACK_IDENTITY = var.spacetrack_username
    SPACE_TRACK_PASSWORD = var.spacetrack_password
    IRON_NAME            = var.paas_app_iron_name
    IRON_PASSWORD        = var.paas_app_iron_password
  }

  routes {
    route = cloudfoundry_route.app_be_internal.id
  }

  service_binding {
    service_instance = cloudfoundry_service_instance.db.id
  }

  service_binding {
    service_instance = cloudfoundry_service_instance.aws_s3_bucket.id
  }

  service_binding {
    service_instance = cloudfoundry_user_provided_service.logit.id
  }
}
