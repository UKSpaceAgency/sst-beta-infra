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
      metric_name                = "${replace(var.env_name, "-", "")}RateLimitRule"
      sampled_requests_enabled   = false
    }
  }

# Content-Type and Body Size Restriction Rule
  rule {
    name     = "restrict-reentry-content-and-size"
    priority = 2

    action {
      block {}
    }

    statement {
      and_statement {
        statement {
          regex_match_statement {
            field_to_match {
              uri_path {}
            }
            regex_string = "^/v1/reentry-event-reports"  # Matches/v1/ephemeris
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }

        statement {
          byte_match_statement {
            field_to_match {
              method {}
            }
            positional_constraint = "EXACTLY"
            search_string         = "POST"
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }

        statement {
          byte_match_statement {
            field_to_match {
              single_header {
                name = "content-type"
              }
            }
            positional_constraint = "EXACTLY"
            search_string         = "application/json"
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
          }
        }

        statement {
          size_constraint_statement {
            field_to_match {
              body {}
            }
            comparison_operator = "GT"
            size                = 104857600
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${replace(var.env_name, "-", "")}ReentryContentAndSize"
      sampled_requests_enabled   = false
    }
  }

# Content-Type and Body Size Restriction Rule
  rule {
    name     = "restrict-ephemeric-text-plain"
    priority = 3

    action {
      block {}
    }

    statement {
      and_statement {
        statement {
          regex_match_statement {
            field_to_match {
              uri_path {}
            }
            regex_string = "^/v1/ephemeris"  # Matches/v1/ephemeris
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }

        statement {
          byte_match_statement {
            field_to_match {
              method {}
            }
            positional_constraint = "EXACTLY"
            search_string         = "POST"
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }

        statement {
          byte_match_statement {
            field_to_match {
              single_header {
                name = "content-type"
              }
            }
            positional_constraint = "EXACTLY"
            search_string         = "text/plain"
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
          }
        }

        statement {
          size_constraint_statement {
            field_to_match {
              body {}
            }
            comparison_operator = "GT"
            size                = 52428800
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${replace(var.env_name, "-", "")}EphemericTextPlain"
      sampled_requests_enabled   = false
    }
  }



# Content-Type and Body Size Restriction Rule
  rule {
    name     = "restrict-post-json-body"
    priority = 4

    action {
      block {}
    }

    statement {
      and_statement {
        statement {
          regex_match_statement {
            field_to_match {
              uri_path {}
            }
            regex_string = "^/v1/.*$"  # Matches everything under /v1/
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }

        statement {
          byte_match_statement {
            field_to_match {
              method {}
            }
            positional_constraint = "EXACTLY"
            search_string         = "POST"
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }

        statement {
          byte_match_statement {
            field_to_match {
              single_header {
                name = "content-type"
              }
            }
            positional_constraint = "EXACTLY"
            search_string         = "application/json"
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
          }
        }

        statement {
          size_constraint_statement {
            field_to_match {
              body {}
            }
            comparison_operator = "GT"
            size                = 20971520
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${replace(var.env_name, "-", "")}RestrictJsonBodyRule"
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