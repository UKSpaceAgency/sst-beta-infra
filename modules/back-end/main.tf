terraform {
  required_providers {
    cloudfoundry = {
      source  = "cloudfoundry-community/cloudfoundry"
      version = ">=0.15.0"
    }
  }
}

locals {
  spacetrack_name     = "${ var.app_spacetrack_name }-${ var.env_tag }"
  api_name            = "${ var.app_api_name }-${ var.env_tag }"
  db_migration_name   = "${ var.app_db_migration_name }-${ var.env_tag }"
  esa_discos_name     = "${ var.app_esa_discos_name }-${ var.env_tag }"
  notifications_name  = "${ var.app_notifications_name }-${ var.env_tag }"
}

resource "cloudfoundry_app" "spacetrack" {

  name              = local.spacetrack_name
  space             = var.space.id
  buildpack         = var.app_be_buildpack
  memory            = var.app_be_worker_memory
  disk_quota        = var.app_be_disk_quota
  timeout           = var.app_be_timeout
  instances         = var.app_be_instances
  path              = var.be_build_asset
  source_code_hash  = filebase64sha256(var.be_build_asset)
  command           = var.app_spacetrack_command
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
    RUN_AT_HOUR                               = var.spacetrack_run_at_hour
    RUN_AT_MINUTE                             = var.spacetrack_run_at_minute
    APP_SENTRY_DSN                            = var.spacetrack_sentry_dsn
    REPEAT_EVERY_SECONDS                      = var.spacetrack_repeat_every_seconds
  }

  routes {
    route = var.app_spacetrack_route.id
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

resource "cloudfoundry_app" "notifications" {

  name              = local.notifications_name
  space             = var.space.id
  buildpack         = var.app_be_buildpack
  memory            = var.app_be_worker_memory
  disk_quota        = var.app_be_disk_quota
  timeout           = var.app_be_timeout
  instances         = var.app_be_instances
  path              = var.be_build_asset
  source_code_hash  = filebase64sha256(var.be_build_asset)
  command           = var.app_notifications_command
  health_check_type = "none"

  annotations = {
    "source_code_hash"  = filebase64sha256(var.be_build_asset)
    "release_timestamp" = "${timestamp()}"
  }

  environment = {
    APP_ENVIRONMENT                           = var.env_tag
    NOTIFY_API_KEY                            = var.notify_api_key
    NOTIFY_INTERVAL                           = var.notify_interval
    NOTIFIERS_WEBHOOK_URL                     = var.notifiers_webhook_url
    APP_SENTRY_DSN                            = var.notifications_sentry_dsn
    REPEAT_EVERY_SECONDS                      = var.notifications_repeat_every_seconds
  }

  routes {
    route = var.app_notifications_route.id
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

resource "cloudfoundry_app" "esa_discos" {

  name              = local.esa_discos_name
  space             = var.space.id
  buildpack         = var.app_be_buildpack
  memory            = var.app_be_worker_memory
  disk_quota        = var.app_be_disk_quota
  timeout           = var.app_be_timeout
  instances         = var.app_be_instances
  path              = var.be_build_asset
  source_code_hash  = filebase64sha256(var.be_build_asset)
  command           = var.app_esa_discos_command
  health_check_type = "none"

  annotations = {
    "source_code_hash"  = filebase64sha256(var.be_build_asset)
    "release_timestamp" = "${timestamp()}"
  }

  environment = {
    APP_ENVIRONMENT                           = var.env_tag
    ESA_DISCOS_ACCESS_TOKEN                   = var.esa_discos_access_token
    NOTIFY_API_KEY                            = var.notify_api_key
    NOTIFY_INTERVAL                           = var.notify_interval
    RUN_AT_HOUR                               = var.esa_run_at_hour
    RUN_AT_MINUTE                             = var.esa_run_at_minute
    APP_SENTRY_DSN                            = var.esa_sentry_dsn
    REPEAT_EVERY_SECONDS                      = var.esa_repeat_every_seconds
  }

  routes {
    route = var.app_esa_discos_route.id
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

resource "cloudfoundry_app" "api" {
  name                       = local.api_name
  space                      = var.space.id
  buildpack                  = var.app_be_buildpack
  memory                     = var.app_api_memory
  disk_quota                 = var.app_api_disk_quota
  timeout                    = var.app_be_timeout
  instances                  = var.app_be_instances
  path                       = var.be_build_asset
  source_code_hash           = filebase64sha256(var.be_build_asset)
  command                    = var.app_api_command
  health_check_type          = "http"
  health_check_http_endpoint = "/"
  health_check_timeout       = "5"

  annotations = {
    "source_code_hash"  = filebase64sha256(var.be_build_asset)
    "release_timestamp" = "${timestamp()}"
  }

  environment = {
    APP_FRONTEND_URL                          = "https://${ var.app_web_route.endpoint }"
    USER_SERVICE_JWT_AUTHENTICATION_SECRET    = var.user_service_jwt_authentication_secret
    USER_SERVICE_RESET_PASSWORD_TOKEN_SECRET  = var.user_service_reset_password_token_secret
    USER_SERVICE_VERIFICATION_TOKEN_SECRET    = var.user_service_verification_token_secret
    APP_ENVIRONMENT                           = var.env_tag
    AUTH0_JWKS_URL                            = var.auth0_jwks_url
    AUTH0_ISSUER                              = "${ var.auth0_issuer }/"
    AUTH0_AUDIENCE                            = var.auth0_audience
    AUTH0_MANAGEMENT_CLIENT_SECRET            = var.auth0_management_client_secret
    AUTH0_MANAGEMENT_CLIENT_ID                = var.auth0_management_client_id
    AUTH0_MANAGEMENT_DOMAIN                   = var.auth0_management_domain
    ESA_DISCOS_ACCESS_TOKEN                   = var.esa_discos_access_token
    HASHID_SALT                               = var.hashid_salt
    APP_SENTRY_DSN	                          = var.api_sentry_dsn
    APP_FAKE_DATA		                      = var.app_fake_data
  }

  routes {
    route = var.app_api_route.id
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
