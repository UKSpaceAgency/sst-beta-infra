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
    SPACE_TRACK_IDENTITY                      = var.spacetrack_username
    SPACE_TRACK_PASSWORD                      = var.spacetrack_password
    IRON_NAME                                 = var.paas_app_iron_name
    IRON_PASSWORD                             = var.paas_app_iron_password
    APP_FRONTEND_URL                          = "${ var.paas_custom_domain_flag == false ? "https://${cloudfoundry_route.app_route_cloud.hostname}.${data.cloudfoundry_domain.cloudapps.name}" : "https://${var.paas_custom_subdomain}.${data.cloudfoundry_domain.custom.name}"}"
    NOTIFY_API_KEY                            = var.notify_api_key
    USER_SERVICE_JWT_AUTHENTICATION_SECRET    = var.user_service_jwt_authentication_secret
    USER_SERVICE_RESET_PASSWORD_TOKEN_SECRET  = var.user_service_reset_password_token_secret
    USER_SERVICE_VERIFICATION_TOKEN_SECRET    = var.user_service_verification_token_secret
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
