terraform {
  required_providers {
    cloudfoundry = {
      source  = "cloudfoundry-community/cloudfoundry"
      version = ">=0.14.2"
    }
  }
}

locals {
  fe_name             = "${ var.app_fe_name }-${ var.env_tag }"
  fe_asset_fullpath   = "${path.module}/${var.github_fe_app_asset}"
  api_name            = "${ var.app_api_name }-${ var.env_tag }"
  api_asset_fullpath  = "${path.module}/${var.github_fe_api_asset}"
}

resource "null_resource" "fe_build_assets" {

  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "${ path.module }/download-private-release.sh ${var.github_owner} ${var.github_fe_repo} ${var.github_release_tag} ${var.github_fe_app_asset} ${ local.fe_asset_fullpath }"

    environment = {
      GIT_TOKEN = var.github_token
    }
  }
}

resource "null_resource" "api_build_assets" {

  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "${ path.module }/download-private-release.sh ${var.github_owner} ${var.github_fe_repo} ${var.github_release_tag} ${var.github_fe_api_asset} ${ local.api_asset_fullpath }"

    environment = {
      GIT_TOKEN = var.github_token
    }
  }
}

resource "cloudfoundry_app" "api" {

  depends_on       = [null_resource.api_build_assets]
  name             = local.api_name
  space            = var.space.id
  buildpack        = var.app_api_buildpack
  memory           = var.app_api_memory
  disk_quota       = var.app_api_disk_quota
  timeout          = var.app_api_timeout
  instances        = var.app_api_instances
  path             = local.api_asset_fullpath
  source_code_hash = "${ filebase64sha256(local.api_asset_fullpath) }"
  command          = var.app_api_command
  strategy         = var.app_api_strategy

  environment = {
    IRON_NAME            = var.iron_name
    IRON_PASSWORD        = var.iron_password
    API_URL              = "http://${ var.app_be_route.hostname }.${var.internal_domain.name}:8080/"
  }

  routes {
    route = var.app_api_route.id
  }

  service_binding {
    service_instance = var.db.id
  }

  service_binding {
    service_instance = var.logit.id
  }
}

resource "cloudfoundry_app" "fe" {

  depends_on        = [null_resource.fe_build_assets]
  name              = local.fe_name
  space             = var.space.id
  buildpack         = var.app_fe_buildpack
  memory            = var.app_fe_memory
  disk_quota        = var.app_fe_disk_quota
  instances         = var.app_fe_instances
  path              = local.fe_asset_fullpath
  source_code_hash  = "${ filebase64sha256(local.fe_asset_fullpath) }"
  command           = var.app_fe_command
  strategy          = var.app_fe_strategy

  environment = {
    IRON_NAME               = var.iron_name
    IRON_PASSWORD           = var.iron_password
    PAGES_LOCATION          = "./.next/server/pages"
    GRAPHQL_URL             = "http://${var.app_api_route.endpoint}:8080/graphql"
    BASE_API_URL            = "https://${ var.app_fe_route.endpoint }/api"
  }

  routes {
    route = var.app_fe_route.id
  }

  service_binding {
    service_instance = var.logit.id
  }
}

resource "cloudfoundry_network_policy" "fe_api_policy" {
  depends_on = [cloudfoundry_app.fe, cloudfoundry_app.api]
  policy {
    source_app = cloudfoundry_app.fe.id
    destination_app = cloudfoundry_app.api.id
    port = "8080"
    protocol = "tcp"
  }
}

resource "cloudfoundry_network_policy" "api_be_policy" {
  depends_on = [cloudfoundry_app.api]
  policy {
    source_app      = cloudfoundry_app.api.id
    destination_app = var.be_app.id
    port            = "8080"
    protocol        = "tcp"
  }
}
