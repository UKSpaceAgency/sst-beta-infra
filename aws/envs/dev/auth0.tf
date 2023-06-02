module "auth0" {
  source   = "../../tf-modules/auth0"
  env_name = var.env_name
  picture_url = "https://assets.publishing.service.gov.uk/government/uploads/system/uploads/organisation/logo/31/UKSA_logo_RGB_60pc.jpg"
  smtp_host = "email-smtp.eu-west-2.amazonaws.com"
  smtp_user = "AKIA47DV7ZDVEKDKKNQ4"
  support_email = "nowakf@gmail.com"
  auth0_domain = "monitor-your-satellites-dev.eu.auth0.com"
  auth_client_id = var.auth_client_id
  auth_client_secret = var.auth_client_secret
  allowed_logout_urls_list = [
    "http://localhost:4200",
    "https://dev.monitor-your-satellites.service.gov.uk",
    "https://web.awsdev.monitor-your-satellites.service.gov.uk"
  ]
  callbacks_list =  [
    "http://127.0.0.1:8000/docs/oauth2-redirect",
    "http://localhost:4200/api/auth/callback/auth0",
    "https://api-dev.monitor-your-satellites.service.gov.uk/docs/oauth2-redirect",
    "https://api.awsdev.monitor-your-satellites.service.gov.uk/docs/oauth2-redirect",
    "https://dev.monitor-your-satellites.service.gov.uk/api/auth/callback/auth0",
    "https://web.awsdev.monitor-your-satellites.service.gov.uk/api/auth/callback/auth0"
  ]
  allowed_web_origins_list = [
    "http://127.0.0.1:8000",
    "http://localhost:4200",
    "http://localhost:8080",
    "https://dev.monitor-your-satellites.service.gov.uk",
    "https://web.awsdev.monitor-your-satellites.service.gov.uk"
  ]

}