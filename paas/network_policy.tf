resource "cloudfoundry_network_policy" "fe_api_policy" {
  policy {
    source_app = cloudfoundry_app.fe.id
    destination_app = cloudfoundry_app.api.id
    port = "8080"
    protocol = "tcp"
  }
}

resource "cloudfoundry_network_policy" "api_be_policy" {
  policy {
    source_app = cloudfoundry_app.api.id
    destination_app = cloudfoundry_app.be.id
    port = "8080"
    protocol = "tcp"
  }
}