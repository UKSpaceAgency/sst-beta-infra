terraform {
  backend "s3" {}
  required_providers {
    cloudfoundry = {
      source  = "cloudfoundry-community/cloudfoundry"
      version = "0.15.5"
    }
  }
}

provider "cloudfoundry" {
  api_url  = var.paas_api_url
  user     = var.paas_username
  password = var.paas_password
}

data "cloudfoundry_space" "space" {
  name     = var.paas_space
  org_name = var.paas_org_name
}

module "network-routes" {
  source              = "./modules/network-routes"
  space               = data.cloudfoundry_space.space
  env_tag             = var.env_tag
}

module "maintenance" {
  source     = "./modules/maintenance"
  depends_on = [module.network-routes]
  space      = data.cloudfoundry_space.space
  env_tag    = var.env_tag
  app_route  = var.maintenance_mode? module.network-routes.web_route : module.network-routes.maintenance_route
}

module "backing-services" {
  source              = "./modules/backing-services"
  space               = data.cloudfoundry_space.space
  env_tag             = var.env_tag
  logit_service_url   = var.logit_service_url
  db_plan             = var.env_tag == "prod" ? "medium-ha-13-high-iops" : "small-13-high-iops"
}

module "back-end" {
  source                                    = "./modules/back-end"
  depends_on                                = [module.network-routes]
  space                                     = data.cloudfoundry_space.space
  be_build_asset                            = var.be_asset
  app_spacetrack_route                      = module.network-routes.spacetrack_route
  app_esa_discos_route                      = module.network-routes.esa_discos_route
  app_api_route                             = module.network-routes.api_route
  db                                        = module.backing-services.db
  s3                                        = module.backing-services.s3
  logit                                     = module.backing-services.logit
  app_web_route                             = module.network-routes.web_route
  env_tag                                   = var.env_tag
  notify_api_key                            = var.notify_api_key
  spacetrack_password                       = var.spacetrack_password
  spacetrack_username                       = var.spacetrack_username
  user_service_jwt_authentication_secret    = var.user_service_jwt_authentication_secret
  user_service_reset_password_token_secret  = var.user_service_reset_password_token_secret
  user_service_verification_token_secret    = var.user_service_verification_token_secret
  auth0_jwks_url                            = var.auth0_jwks_url
  auth0_audience                            = var.auth0_audience
  auth0_issuer                              = var.auth0_issuer
  auth0_management_client_secret            = var.auth0_management_client_secret
  auth0_management_client_id                = var.auth0_management_client_id
  auth0_management_domain                   = var.auth0_management_domain
  auth0_client_credentials_flow_issuer      = var.auth0_client_credentials_flow_issuer
  esa_discos_access_token                   = var.esa_discos_access_token
  hashid_salt                               = var.hashid_salt
  notifiers_webhook_url                     = var.notifiers_webhook_url
  api_sentry_dsn                            = var.app_sentry_dsn
  app_sentry_sample_rate                    = var.app_sentry_sample_rate
  spacetrack_sentry_dsn                     = var.app_spacetrack_worker_sentry_dsn
  app_fake_data			                    = var.app_fake_data
  esa_repeat_every_seconds                  = var.esa_repeat_every_seconds
  esa_run_at_hour                           = var.esa_run_at_hour
  esa_run_at_minutes                        = var.esa_run_at_minutes
  esa_sentry_dsn                            = var.esa_sentry_dsn
  spacetrack_repeat_every_seconds           = var.spacetrack_repeat_every_seconds
  spacetrack_run_at_hour                    = var.spacetrack_run_at_hour
  spacetrack_run_at_minute                  = var.spacetrack_run_at_minute
  notifications_repeat_every_seconds        = var.notifications_repeat_every_seconds
  notifications_sentry_dsn                  = var.notifications_sentry_dsn
  notify_contact_analyst_email              = var.notify_contact_analyst_email
  app_notifications_route                   = module.network-routes.notifications_route
}

module "front-end" {
  source              = "./modules/front-end"
  depends_on          = [module.back-end.api_app, module.network-routes]
  space               = data.cloudfoundry_space.space
  fe_build_asset      = var.app_asset
  app_web_route       = var.maintenance_mode ? module.network-routes.maintenance_route : module.network-routes.web_route
  app_api_route       = module.network-routes.api_route
  db                  = module.backing-services.db
  logit               = module.backing-services.logit
  env_tag             = var.env_tag
  i18nexus_api_key    = var.i18nexus_api_key
  cosmic_bucket_slug  = var.cosmic_bucket_slug
  cosmic_read_key     = var.cosmic_read_key
  cosmic_preview_secret = var.cosmic_preview_secret
  piwik_id            = var.piwik_id
  nextauth_secret     = var.nextauth_secret
  auth0_issuer        = var.auth0_issuer
  auth0_client_id     = var.auth0_client_id
  auth0_client_secret = var.auth0_client_secret
  auth0_audience      = var.auth0_audience
}

