terraform {
  required_providers {
    cloudfoundry = {
      source  = "cloudfoundry-community/cloudfoundry"
      version = ">=0.15.0"
    }
  }
}

locals {
  build_asset_fullpath = "${path.module}/${var.build_asset}"
}

resource "null_resource" "mp_build_assets" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "cd ${ path.module}/app && zip -r mp.zip ./* && mv mp.zip .. "
  }
}

resource "cloudfoundry_app" "mp" {
  depends_on        = [null_resource.mp_build_assets]
  name              = "${ var.app_name }-${ var.env_tag }"
  space             = var.space.id
  buildpack         = var.app_buildpack
  path              = local.build_asset_fullpath
  //source_code_hash  = fileexists(local.build_asset_fullpath) ? filebase64sha256(local.build_asset_fullpath) : "0"

}
