locals {
  description = "Public zone for ${var.name}"
  managed_by  = "terraform"
}

resource "aws_route53_zone" "this" {
  name              = var.name
  comment           = local.description
  delegation_set_id = var.delegation_set_id
  force_destroy     = var.force_destroy

  tags = {
    "Name"          = var.name
    "ProductDomain" = var.product_domain
    "Environment"   = var.environment
    "Description"   = local.description
    "ManagedBy"     = local.managed_by
  }
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.this.zone_id
  name = "www"
  type = "CNAME"
  records = [var.name]
  ttl = "3600"
}

resource "aws_route53_record" "A-records" {

    for_each = var.dns_records_A
      zone_id = aws_route53_zone.this.zone_id
      name = each.key
      records = [each.value]
      type = "A"
      ttl = "3600"
}

resource "aws_route53_record" "CNAME-records" {

    for_each = var.dns_records_CNAME
      zone_id = aws_route53_zone.this.zone_id
      name = each.key
      records = [each.value]
      type = "CNAME"
      ttl = "3600"
}

