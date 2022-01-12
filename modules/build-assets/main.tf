terraform {
  required_providers {
    cloudfoundry = {
      source  = "cloudfoundry-community/cloudfoundry"
      version = ">=0.15.0"
    }
  }
}

locals {
  be_asset_fullpath  = "${path.module}/${var.github_be_asset}"
  fe_asset_fullpath  = "${path.module}/${var.github_fe_app_asset}"
  api_asset_fullpath = "${path.module}/${var.github_fe_api_asset}"
}

resource "null_resource" "be_build_assets" {

  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "${path.module}/download-private-release.sh ${var.github_be_owner} ${var.github_be_repo} ${var.github_release_tag} ${var.github_be_asset} ${ local.be_asset_fullpath }"

    environment = {
      GIT_TOKEN = var.github_token
    }
  }
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