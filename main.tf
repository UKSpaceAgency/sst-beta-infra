terraform {
  backend "s3" {}
  required_providers {
    cloudfoundry = {
      source  = "cloudfoundry-community/cloudfoundry"
      version = ">=0.15.0"
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
  source  = "./modules/network-routes"
  space   = data.cloudfoundry_space.space
  env_tag = var.env_tag
}

module "maintenance" {
  source     = "./modules/maintenance"
  depends_on = [module.network-routes.maintenance_route]
  space      = data.cloudfoundry_space.space
  env_tag    = var.env_tag
  app_route  = var.maintenance_mode ? module.network-routes.web_route : module.network-routes.maintenance_route
}

module "backing-services" {
  source              = "./modules/backing-services"
  space               = data.cloudfoundry_space.space
  env_tag             = var.env_tag
  logit_service_url   = var.logit_service_url
}

module "back-end" {
  source                                    = "./modules/back-end"
  space                                     = data.cloudfoundry_space.space
  be_build_asset                            = var.be_asset
  app_spacetrack_route                      = module.network-routes.spacetrack_route
  app_api_route                             = module.network-routes.api_route
  db                                        = module.backing-services.db
  s3                                        = module.backing-services.s3
  logit                                     = module.backing-services.logit
  app_web_route                             = module.network-routes.web_route
  env_tag                                   = var.env_tag
  iron_name                                 = var.iron_name
  iron_password                             = var.iron_password
  notify_api_key                            = var.notify_api_key
  spacetrack_password                       = var.spacetrack_password
  spacetrack_username                       = var.spacetrack_username
  user_service_jwt_authentication_secret    = var.user_service_jwt_authentication_secret
  user_service_reset_password_token_secret  = var.user_service_reset_password_token_secret
  user_service_verification_token_secret    = var.user_service_verification_token_secret
  run_at_hour                               = var.spacetrack_run_at_hour
  run_at_minute                             = var.spacetrack_run_at_minute
}

module "front-end" {
  depends_on          = [module.back-end.api_app]
  source              = "./modules/front-end"
  space               = data.cloudfoundry_space.space
  fe_build_asset      = var.app_asset
  app_web_route       = var.maintenance_mode ? module.network-routes.maintenance_route : module.network-routes.web_route
  app_api_route       = module.network-routes.api_route
  db                  = module.backing-services.db
  logit               = module.backing-services.logit
  env_tag             = var.env_tag
  iron_name           = var.iron_name
  iron_password       = var.iron_password
  i18nexus_api_key    = var.i18nexus_api_key
  cosmic_bucket_slug  = var.cosmic_bucket_slug
  cosmic_read_key     = var.cosmic_read_key
  cosmic_preview_secret = var.cosmic_preview_secret
  piwik_id            = var.piwik_id
}


