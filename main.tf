terraform {
  backend "s3" {}
  required_providers {
    cloudfoundry = {
      source  = "cloudfoundry-community/cloudfoundry"
      version = ">=0.14.2"
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

module "maintenance" {
  source    = "./modules/maintenance"
  space     = data.cloudfoundry_space.space
  env_tag   = var.env_tag
}

module "backing-services" {
  source              = "./modules/backing-services"
  space               = data.cloudfoundry_space.space
  env_tag             = var.env_tag
  logit_service_url   = var.logit_service_url
}

module "network" {
  source  = "./modules/network"
  space   = data.cloudfoundry_space.space
  env_tag = var.env_tag
}

module "back-end" {
  source                                    = "./modules/back-end"
  space                                     = data.cloudfoundry_space.space
  app_be_route                              = module.network.be_route
  db                                        = module.backing-services.db
  s3                                        = module.backing-services.s3
  logit                                     = module.backing-services.logit
  app_fe_route                              = module.network.fe_route
  env_tag                                   = var.env_tag
  github_token                              = var.github_token
  iron_name                                 = var.iron_name
  iron_password                             = var.iron_password
  notify_api_key                            = var.notify_api_key
  spacetrack_password                       = var.spacetrack_password
  spacetrack_username                       = var.spacetrack_username
  user_service_jwt_authentication_secret    = var.user_service_jwt_authentication_secret
  user_service_reset_password_token_secret  = var.user_service_reset_password_token_secret
  user_service_verification_token_secret    = var.user_service_verification_token_secret
}

module "front-end" {
  depends_on          = [module.back-end.be_app]
  source              = "./modules/front-end"
  space               = data.cloudfoundry_space.space
  app_fe_route        = module.network.fe_route
  app_api_route       = module.network.api_route
  app_be_route        = module.network.be_route
  internal_domain     = module.network.internal_domain
  cloudapps_domain    = module.network.cloudapps_domain
  custom_domain       = module.network.custom_domain
  db                  = module.backing-services.db
  logit               = module.backing-services.logit
  be_app              = module.back-end.be_app
  env_tag             = var.env_tag
  github_token        = var.github_token
  iron_name           = var.iron_name
  iron_password       = var.iron_password
}
