variable "name" {
  type        = string
  description = "Name of the hosted zone"
}

variable "product_domain" {
  type        = string
  description = "Abbreviation of the product domain this Route 53 zone belongs to"
}

variable "environment" {
  type        = string
  description = "Environment this Route 53 zone belongs to"
}

variable "delegation_set_id" {
  type        = string
  default     = ""
  description = "The delegation set ID whose NS records will be assigned the hosted zone"
}

variable "force_destroy" {
  type        = string
  default     = false
  description = "Whether to destroy all records inside if the hosted zone is deleted"
}

variable "dns_records_A" {
  description = "map"
  type = map(string)
  default     = {
      "wojtas" = "1.1.1.1"
      "wojtas2" = "2.2.2.2"
  }
}

variable "dns_records_CNAME" {
  description = "map"
  type = map(string)
  default     = {
      www-dev = "d16nxratuxxje8.cloudfront.net"
      "_238c0ef85e86d097a18604dd74ea1726.www-dev" = "_602c9f3f757601639b5599241beac658.vrztfgqhxj.acm-validations.aws."
      api-dev = "d10qurojk9ecxy.cloudfront.net"
      "_611464eb053bab8dbfc5c9f63ee5a5ce.api-dev" = "_25c48ef80fb5a21bcfc606956c99bb56.vrztfgqhxj.acm-validations.aws."
  }
}
