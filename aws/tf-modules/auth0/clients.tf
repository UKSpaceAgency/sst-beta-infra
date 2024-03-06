resource "auth0_client" "web_client" {
  allowed_logout_urls                 = var.allowed_logout_urls_list
  app_type                            = "regular_web"
  callbacks                           = var.callbacks_list
  cross_origin_auth                   = "false"
  custom_login_page_on                = "true"
  grant_types                         = ["authorization_code", "http://auth0.com/oauth/grant-type/password-realm", "implicit", "password", "refresh_token"]
  is_first_party                      = "true"
  is_token_endpoint_ip_header_trusted = "false"

  jwt_configuration {
    alg                 = "RS256"
    lifetime_in_seconds = "36000"
    secret_encoded      = "false"
  }

  logo_uri = var.picture_url
  name     = "application"

  native_social_login {
    apple {
      enabled = "false"
    }

    facebook {
      enabled = "false"
    }
  }

  oidc_conformant = "true"

  refresh_token {
    expiration_type              = "expiring"
    idle_token_lifetime          = "172800"
    infinite_idle_token_lifetime = "false"
    infinite_token_lifetime      = "true"
    leeway                       = "0"
    rotation_type                = "non-rotating"
    token_lifetime               = "2592000"
  }

  sso          = "false"
  sso_disabled = "false"
  web_origins  = var.allowed_web_origins_list
}

resource "auth0_client" "sst_backend_m2m" {
  app_type                            = "non_interactive"
  cross_origin_auth                   = "false"
  custom_login_page_on                = "true"
  grant_types                         = ["client_credentials"]
  is_first_party                      = "true"
  is_token_endpoint_ip_header_trusted = "false"

  jwt_configuration {
    alg                 = "RS256"
    lifetime_in_seconds = "36000"
    secret_encoded      = "false"
  }

  name = "Auth0 Management API - SST Backend"

  native_social_login {
    apple {
      enabled = "false"
    }

    facebook {
      enabled = "false"
    }
  }

  oidc_conformant = "true"

  refresh_token {
    expiration_type              = "non-expiring"
    idle_token_lifetime          = "2592000"
    infinite_idle_token_lifetime = "true"
    infinite_token_lifetime      = "true"
    leeway                       = "0"
    rotation_type                = "non-rotating"
    token_lifetime               = "31557600"
  }

  sso          = "false"
  sso_disabled = "false"
}