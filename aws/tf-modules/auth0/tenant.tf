resource "auth0_tenant" "tenant_config" {
  default_audience  = "https://monitor-your-satellites-${var.env_name}.eu.auth0.com/api/v2/"
  default_directory = "Username-Password-Authentication"
  enabled_locales   = ["en"]

  flags {
    allow_legacy_delegation_grant_types    = "false"
    allow_legacy_ro_grant_types            = "false"
    allow_legacy_tokeninfo_endpoint        = "false"
    dashboard_insights_view                = "false"
    dashboard_log_streams_next             = "false"
    disable_clickjack_protection_headers   = "false"
    disable_fields_map_fix                 = "false"
    disable_management_api_sms_obfuscation = "false"
    enable_adfs_waad_email_verification    = "false"
    enable_apis_section                    = "false"
    enable_client_connections              = "false"
    enable_custom_domain_in_emails         = "false"
    enable_dynamic_client_registration     = "false"
    enable_idtoken_api2                    = "false"
    enable_legacy_logs_search_v2           = "false"
    enable_legacy_profile                  = "false"
    enable_pipeline2                       = "false"
    enable_public_signup_user_exists_error = "false"
    mfa_show_factor_list_on_enrollment     = "false"
    no_disclose_enterprise_connections     = "false"
    revoke_refresh_token_grant             = "false"
    use_scope_descriptions_for_consent     = "false"
  }

  friendly_name         = "Monitor your satellites"
  picture_url           = var.picture_url
  sandbox_version       = "12"
  support_email         = var.support_email
  idle_session_lifetime = 72
  session_lifetime      = 168

}
