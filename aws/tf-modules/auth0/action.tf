resource "auth0_action" "custom_action" {
  code = "const axios = require(\"axios\");\n\n/**\n* Handler that will be called during the execution of a PostUserRegistration flow.\n*\n* @param {Event} event - Details about the context and user that has registered.\n*/\nexports.onExecutePostUserRegistration = async (event) => {\n  axios.post(`$${event.secrets.ISSUER}/dbconnections/change_password`, {\n    \"client_id\": event.secrets.CLIENT_ID,\n    \"email\": event.user.email,\n    \"connection\": event.connection.name,\n  })\n};\n"


  dependencies {
    name    = "axios"
    version = "1.2.1"
  }

  name    = "Reset password"
  runtime = "node18"

  supported_triggers {
    id      = "post-user-registration"
    version = "v2"
  }
}
