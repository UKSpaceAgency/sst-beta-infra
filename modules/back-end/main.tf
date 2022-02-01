terraform {
  required_providers {
    cloudfoundry = {
      source  = "cloudfoundry-community/cloudfoundry"
      version = ">=0.15.0"
    }
  }
}

locals {
  be_batch_name       = "${ var.app_be_batch_name }-${ var.env_tag }"
  be_interactive_name = "${ var.app_be_interactive_name }-${ var.env_tag }"
  db_migration_name   = "${ var.app_db_migration_name }-${ var.env_tag }"
}


resource "cloudfoundry_app" "be_batch" {

  name              = local.be_batch_name
  space             = var.space.id
  buildpack         = var.app_be_buildpack
  memory            = var.app_be_memory
  disk_quota        = var.app_be_disk_quota
  timeout           = var.app_be_timeout
  instances         = var.app_be_instances
  path              = var.be_build_asset
  source_code_hash  = filebase64sha256(var.be_build_asset)
  command           = var.app_be_batch_command
  health_check_type = "none"

  annotations = {
    "source_code_hash"  = filebase64sha256(var.be_build_asset)
    "release_timestamp" = "${timestamp()}"
  }

  environment = {
    SPACE_TRACK_IDENTITY                      = var.spacetrack_username
    SPACE_TRACK_PASSWORD                      = var.spacetrack_password
    NOTIFY_API_KEY                            = var.notify_api_key
    NOTIFY_INTERVAL                           = var.notify_interval
    APP_ENVIRONMENT                           = var.env_tag
    RUN_AT_HOUR                               = var.run_at_hour
    RUN_AT_MINUTE                             = var.run_at_minute
  }

  routes {
    route = var.app_be_batch_route.id
  }

  service_binding {
    service_instance = var.db.id
  }

  service_binding {
    service_instance = var.s3.id
  }

  service_binding {
    service_instance = var.redis.id
  }

  service_binding {
    service_instance = var.logit.id
  }
}

resource "cloudfoundry_app" "be_interactive" {

  name              = local.be_interactive_name
  space             = var.space.id
  buildpack         = var.app_be_buildpack
  memory            = var.app_be_memory
  disk_quota        = var.app_be_disk_quota
  timeout           = var.app_be_timeout
  instances         = var.app_be_instances
  path              = var.be_build_asset
  source_code_hash  = filebase64sha256(var.be_build_asset)
  command           = var.app_be_interactive_command

  annotations = {
    "source_code_hash"  = filebase64sha256(var.be_build_asset)
    "release_timestamp" = "${timestamp()}"
  }

  environment = {
    IRON_NAME                                 = var.iron_name
    IRON_PASSWORD                             = var.iron_password
    APP_FRONTEND_URL                          = "https://${ var.app_fe_route.endpoint }"
    USER_SERVICE_JWT_AUTHENTICATION_SECRET    = var.user_service_jwt_authentication_secret
    USER_SERVICE_RESET_PASSWORD_TOKEN_SECRET  = var.user_service_reset_password_token_secret
    USER_SERVICE_VERIFICATION_TOKEN_SECRET    = var.user_service_verification_token_secret
    APP_ENVIRONMENT                           = var.env_tag
  }

  routes {
    route = var.app_be_interactive_route.id
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

  name              = local.db_migration_name
  space             = var.space.id
  buildpack         = var.app_be_buildpack
  path              = var.be_build_asset
  source_code_hash  = filebase64sha256(var.be_build_asset)
  command           = var.app_db_migration_command
  health_check_type = "none"

  annotations = {
    "source_code_hash"  = filebase64sha256(var.be_build_asset)
    "release_timestamp" = "${timestamp()}"
  }

  service_binding {
    service_instance = var.db.id
  }

  service_binding {
    service_instance = var.logit.id
  }
}
