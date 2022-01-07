resource "null_resource" "fe_build_assets" {

  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "./download-private-release.sh ${var.github_owner} ${var.github_fe_repo} ${var.github_release_tag} ${var.github_fe_app_asset} ./${var.github_fe_app_asset}"

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
    command = "./download-private-release.sh ${var.github_owner} ${var.github_fe_repo} ${var.github_release_tag} ${var.github_fe_api_asset} ./${var.github_fe_api_asset}"

    environment = {
      GIT_TOKEN = var.github_token
    }
  }
}

resource "null_resource" "be_build_assets" {

  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "./download-private-release.sh ${var.github_thepsc} ${var.github_be_repo} ${var.github_release_tag} ${var.github_be_asset} ./${var.github_be_asset}"

    environment = {
      GIT_TOKEN = var.github_token
    }
  }
}

resource "null_resource" "mp_build_assets" {

  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "cd ../maintenance-page && zip -r mp.zip ./* && mv mp.zip ../paas/ && cd ../paas"
  }

}