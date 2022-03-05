terraform {
  required_providers {
    cloudfoundry = {
      source  = "cloudfoundry-community/cloudfoundry"
      version = ">=0.15.0"
    }
  }
}

locals {
  fe_name             = "${ var.app_fe_name }-${ var.env_tag }"
}

resource "cloudfoundry_app" "fe" {

  name              = local.fe_name
  space             = var.space.id
  buildpack         = var.app_fe_buildpack
  memory            = var.app_fe_memory
  disk_quota        = var.app_fe_disk_quota
  instances         = var.app_fe_instances
  path              = var.fe_build_asset
  source_code_hash  = filebase64sha256(var.fe_build_asset)
  command           = var.app_fe_command
  strategy          = var.app_fe_strategy

  annotations = {
    "source_code_hash"  = filebase64sha256(var.fe_build_asset)
    "release_timestamp" = "${timestamp()}"
  }

  environment = {
    IRON_NAME               = var.iron_name
    IRON_PASSWORD           = var.iron_password
    PAGES_LOCATION          = "./.next/server/pages"
    //GRAPHQL_URL             = "http://${var.app_api_route.endpoint}:8080/graphql"
    BASE_API_URL            = "https://${ var.app_fe_route.endpoint }/api"
    PIWIK_ID                = var.piwik_id
  }

  routes {
    route = var.app_fe_route.id
  }

  service_binding {
    service_instance = var.logit.id
  }
}