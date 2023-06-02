resource "auth0_email" "smtp_config" {
  credentials {
    smtp_host = var.smtp_host
    smtp_port = "587"
    smtp_user = var.smtp_user
  }

  default_from_address = "do-not-reply@monitor-my-satellites.space"
  enabled              = "true"
  name                 = "smtp"
}
