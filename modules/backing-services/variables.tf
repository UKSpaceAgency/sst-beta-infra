variable "env_tag" {
  default = "dev"
}

variable "db_name" {
  default = "mys-db"
}

variable "db_service" {
  default = "postgres"
}

variable "db_plan" {
  default = "small-13"
}

variable "db_extensions" {
  //default = "{\"enable_extensions\": [\"pg_stat_statements\"]}"
}

variable "s3_name" {
  default = "mys-s3"
}

variable "s3_service" {
  default = "aws-s3-bucket"
}

variable "logit_service_name" {
  default = "logit-ssl-drain"
}

variable "logit_service_url" {}

variable "space" {}

