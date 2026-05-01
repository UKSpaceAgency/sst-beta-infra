# HMAC secret used by the BE to sign short-lived download URLs
# (mint_signed_url / verify_signed_url in app/utils/signed_urls.py).
#
# Kept as a separate AWS Secrets Manager secret rather than a key inside the
# main `${env}-backend` JSON secret so it can be fully Terraform-managed —
# generated once by `random_id`, rotated by tainting either resource.

resource "random_id" "download_token" {
  byte_length = 32
}

resource "aws_secretsmanager_secret" "download_token" {
  name        = "${var.env_name}-backend-download-token"
  description = "HMAC secret for signing report download URLs"
}

resource "aws_secretsmanager_secret_version" "download_token" {
  secret_id     = aws_secretsmanager_secret.download_token.id
  secret_string = random_id.download_token.b64_url
}
