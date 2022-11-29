terraform {
  required_providers {
    cloudfoundry = {
      source  = "cloudfoundry-community/cloudfoundry"
      version = "0.15.5"
    }
  }
}

locals {
  web_name             = "${ var.app_web_name }-${ var.env_tag }"
}

resource "cloudfoundry_app" "web" {

  name              = local.web_name
  space             = var.space.id
  buildpack         = var.app_web_buildpack
  memory            = var.app_web_memory
  disk_quota        = var.app_web_disk_quota
  instances         = var.app_web_instances
  path              = var.fe_build_asset
  source_code_hash  = filebase64sha256(var.fe_build_asset)
  command           = var.app_web_command
  strategy          = var.app_web_strategy

  annotations = {
    "source_code_hash"  = filebase64sha256(var.fe_build_asset)
    "release_timestamp" = "${timestamp()}"
  }

  environment = {
    API_URL                 = "https://${ var.app_api_route.endpoint }"
    BASE_API_URL            = "https://${ var.app_web_route.endpoint }/api/graphql"
    NEXTAUTH_URL            = "https://${ var.app_web_route.endpoint }"
    NEXTAUTH_SECRET         = var.nextauth_secret
    AUTH0_BASEURL           = var.auth0_issuer
    AUTH0_CLIENT_ID         = var.auth0_client_id
    AUTH0_CLIENT_SECRET     = var.auth0_client_secret
    PAGES_LOCATION          = "./.next/server/pages"
    I18NEXUS_API_KEY        = var.i18nexus_api_key
    COSMIC_BUCKET_SLUG      = var.cosmic_bucket_slug
    COSMIC_READ_KEY         = var.cosmic_read_key
    COSMIC_PREVIEW_SECRET   = var.cosmic_preview_secret
    PIWIK_ID                = var.piwik_id
    AUTH0_AUDIENCE          = var.auth0_audience
  }

  routes {
    route = var.app_web_route.id
  }

  service_binding {
    service_instance = var.logit.id
  }
}
