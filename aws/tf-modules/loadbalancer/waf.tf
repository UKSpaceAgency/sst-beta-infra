resource "aws_wafv2_web_acl" "rate-based-acl" {
  name        = "rate-based-acl-for${var.env_name}"
  description = "Regional rate based statement."
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "rule-1"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 10000
        aggregate_key_type = "IP"

        #        scope_down_statement {
        #          geo_match_statement {
        #            country_codes = ["US", "NL"]
        #          }
        #        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${replace(var.env_name, "-", "")}WafWebACL"
      sampled_requests_enabled   = false
    }
  }


  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "${replace(var.env_name, "-", "")}WafWebACL"
    sampled_requests_enabled   = false
  }
}


resource "aws_wafv2_web_acl_association" "alb_waf_association" {
  resource_arn = aws_lb.alb.arn
  web_acl_arn  = aws_wafv2_web_acl.rate-based-acl.arn
}