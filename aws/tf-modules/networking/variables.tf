variable "env_name" { type = string }
variable "az_names" {
  type    = list(string)
  default = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
}
variable "cidr_block" {
  type = string
  default = "172.20.0.0/16"
}

variable "public_subnet_bits" {
  type = number
  default = 8
}

variable "private_subnet_bits" {
  type = number
  default = 8
}