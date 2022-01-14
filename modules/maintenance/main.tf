terraform {
  required_providers {
    cloudfoundry = {
      source  = "cloudfoundry-community/cloudfoundry"
      version = ">=0.15.0"
    }
  }
}

resource "cloudfoundry_app" "mp" {
  name              = "${ var.app_name }-${ var.env_tag }"
  space             = var.space.id
  buildpack         = var.app_buildpack
  memory            = var.app_memory
  path              = var.build_asset
  source_code_hash  = filebase64sha256(var.build_asset)
  strategy          = var.app_strategy

  routes {
    route = var.app_route.id
  }

}
