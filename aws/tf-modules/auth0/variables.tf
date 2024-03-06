variable "env_name" { type = string }
variable "picture_url" { type = string }
variable "support_email" { type = string }

variable "smtp_user" { type = string }
variable "smtp_host" { type = string }

variable "auth0_domain" { type = string }
variable "auth_client_id" { type = string }
variable "auth_client_secret" { type = string }

variable "allowed_logout_urls_list" {
  type = list(string)
}

variable "callbacks_list" {
  type = list(string)
}

variable "allowed_web_origins_list" {
  type = list(string)
}