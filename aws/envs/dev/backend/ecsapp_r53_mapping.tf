data "aws_lb" "selected" {
  name = data.terraform_remote_state.stack.outputs.alb_name
}

data "aws_route53_zone" "selected" {
  name         = "${local.local_r53_domain}."
  private_zone = false
}

resource "aws_route53_record" "app_record_a" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${var.app_name}.${local.local_r53_domain}"
  type    = "A"

  alias {
    name                   = data.aws_lb.selected.dns_name
    zone_id                = data.aws_lb.selected.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "data_cache_record_a" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "data-cache-client.${local.local_r53_domain}"
  type    = "A"

  alias {
    name                   = data.aws_lb.selected.dns_name
    zone_id                = data.aws_lb.selected.zone_id
    evaluate_target_health = false
  }
}