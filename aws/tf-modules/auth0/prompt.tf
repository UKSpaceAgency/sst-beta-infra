resource "auth0_prompt" "prompt" {
  identifier_first               = "false"
  universal_login_experience     = "new"
  webauthn_platform_first_factor = "false"
}
