resource "null_resource" "fe_api_zip" {
  provisioner "local-exec" {
    command = "./download-private-release.sh ${var.github_owner} ${var.github_fe_repo} ${var.github_release_tag} ${var.github_fe_api_asset} ./${var.github_fe_api_asset}"

    environment = {
      GIT_TOKEN = var.github_token
    }
  }
}

resource "null_resource" "fe_sst_zip" {
  provisioner "local-exec" {
    command = "./download-private-release.sh ${var.github_owner} ${var.github_fe_repo} ${var.github_release_tag} ${var.github_fe_sst_asset} ./${var.github_fe_sst_asset}"

    environment = {
      GIT_TOKEN = var.github_token
    }
  }
}