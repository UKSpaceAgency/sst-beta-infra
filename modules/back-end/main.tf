terraform {
  required_providers {
    cloudfoundry = {
      source  = "cloudfoundry-community/cloudfoundry"
      version = ">=0.15.0"
    }
  }
}

locals {
  be_name           = "${ var.app_be_name }-${ var.env_tag }"
  be_asset_fullpath = "${path.module}/${var.github_be_asset}"
  db_migration_name = "${ var.app_db_migration_name }-${ var.env_tag }"
}

resource "null_resource" "be_build_assets" {

  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "${path.module}/download-private-release.sh ${var.github_owner} ${var.github_be_repo} ${var.github_release_tag} ${var.github_be_asset} ${ local.be_asset_fullpath }"

    environment = {
      GIT_TOKEN = var.github_token
    }
  }
}

resource "cloudfoundry_app" "be" {

  depends_on        = [null_resource.be_build_assets]
  name              = local.be_name
  space             = var.space.id
  buildpack         = var.app_be_buildpack
  memory            = var.app_be_memory
  disk_quota        = var.app_be_disk_quota
  timeout           = var.app_be_timeout
  instances         = var.app_be_instances
  path              = local.be_asset_fullpath
  source_code_hash  = fileexists(local.be_asset_fullpath) ? filebase64sha256(local.be_asset_fullpath) : "0"
  command           = var.app_be_command

  environment = {
    SPACE_TRACK_IDENTITY                      = var.spacetrack_username
    SPACE_TRACK_PASSWORD                      = var.spacetrack_password
    IRON_NAME                                 = var.iron_name
    IRON_PASSWORD                             = var.iron_password
    APP_FRONTEND_URL                          = "https://${ var.app_fe_route.endpoint }"
    NOTIFY_API_KEY                            = var.notify_api_key
    USER_SERVICE_JWT_AUTHENTICATION_SECRET    = var.user_service_jwt_authentication_secret
    USER_SERVICE_RESET_PASSWORD_TOKEN_SECRET  = var.user_service_reset_password_token_secret
    USER_SERVICE_VERIFICATION_TOKEN_SECRET    = var.user_service_verification_token_secret
    APP_ENVIRONMENT                           = var.env_tag
  }

  routes {
    route = var.app_be_route.id
  }

  service_binding {
    service_instance = var.db.id
  }

  service_binding {
    service_instance = var.s3.id
  }

  service_binding {
    service_instance = var.logit.id
  }
}

resource "cloudfoundry_app" "db_migration" {

  depends_on        = [null_resource.be_build_assets]
  name              = local.db_migration_name
  space             = var.space.id
  buildpack         = var.app_be_buildpack
  path              = local.be_asset_fullpath
  source_code_hash  = fileexists(local.be_asset_fullpath) ? filebase64sha256(local.be_asset_fullpath) : "0"
  command           = var.app_db_migration_command
  health_check_type = "none"

  service_binding {
    service_instance = var.db.id
  }

  service_binding {
    service_instance = var.logit.id
  }
}
