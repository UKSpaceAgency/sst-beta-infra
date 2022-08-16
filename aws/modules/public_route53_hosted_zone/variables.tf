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
      dev = "d16nxratuxxje8.cloudfront.net"
      "_6bd2aec10b1f378e33e6c9f0d5abc319.dev" = "_f5d5cfecc1a1cc00bb013db2204d4969.zxwlrjxpwn.acm-validations.aws."
      api-dev = "d10qurojk9ecxy.cloudfront.net"
      "_611464eb053bab8dbfc5c9f63ee5a5ce.api-dev" = "_25c48ef80fb5a21bcfc606956c99bb56.vrztfgqhxj.acm-validations.aws."
      api-demo = "deifh0fuhtqpn.cloudfront.net"
      "_9a607ca3dc863fc1da769224448f838f.api-demo" = "_c8cf621010a08f698ca8ec9714248b31.zxwlrjxpwn.acm-validations.aws."
      demo = "d2d3pngzkm5msd.cloudfront.net"
      "_13daf2d2cfb9c775577fb5a495076822.demo" = "_b05718b68e0513434750a5d135ed215d.zxwlrjxpwn.acm-validations.aws."
  }
}
