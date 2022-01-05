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

  /*
  provisioner "local-exec" {
    command = "unzip -u ${var.github_fe_app_asset} ${var.paas_app_fe_proxy_conf}"
  }

  provisioner "local-exec" {
    command =  "echo 'location /api { proxy_http_version 1.1; proxy_set_header Connection \"\"; proxy_pass http://${var.paas_app_api_route_name}.apps.internal:8080/graphql/; }' > ${var.paas_app_fe_proxy_conf}"
  }

  provisioner "local-exec" {
    command = "zip ${var.github_fe_app_asset} ${var.paas_app_fe_proxy_conf}"
  }
  */
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