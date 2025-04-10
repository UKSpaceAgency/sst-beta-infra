resource "aws_wafv2_web_acl" "rate-based-acl" {
  name        = "rate-based-acl-for${var.env_name}"
  description = "Regional rate based statement."
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  custom_response_body {
    content      = jsonencode(
      {
        error = "not a text"
      }
    )
    content_type = "APPLICATION_JSON"
    key          = "NOT_A_TEXT"
  }

  custom_response_body {
    content      = jsonencode(
      {
        error = "not json"
      }
    )
    content_type = "APPLICATION_JSON"
    key          = "NOT_A_JSON"
   }

   custom_response_body {
    content      = jsonencode(
      {
        error = "payload too big"
      }
    )
    content_type = "APPLICATION_JSON"
    key          = "GENERIC_431_TOO_BIG"
  }
  custom_response_body {
    content      = jsonencode(
      {
        error = "reentry payload too big"
      }
    )
    content_type = "APPLICATION_JSON"
    key          = "REENTRY_TOO_BIG_431"
  }

    rule {
      name     = "restrict-reentry-content-size"
      priority = 1

      action {
        block {
          custom_response {
            custom_response_body_key = "REENTRY_TOO_BIG_431"
            response_code            = 431
          }
        }
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
        metric_name                = "${replace(var.env_name, "-", "")}ReentryContentSize"
        sampled_requests_enabled   = false
      }
    }

  rule {
      name     = "restrict-generic-size"
      priority = 2

      action {
        block {
          custom_response {
            custom_response_body_key = "GENERIC_431_TOO_BIG"
            response_code            = 431
          }
        }
      }

      statement {
        and_statement {
          statement {
            regex_match_statement {
              field_to_match {
                uri_path {}
              }
              regex_string ="^/v1/(analyses|conjunction-reports|ephemeris|manoeuvre_plots|tips)"
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
        metric_name                = "${replace(var.env_name, "-", "")}RestrictGenericSize"
        sampled_requests_enabled   = false
      }
    }


  rule {
    name     = "restrict-post-text-plain-ephemeric"
    priority = 3

    action {
        block {
          custom_response {
            custom_response_body_key = "NOT_A_TEXT"
            response_code            = 400
          }
        }
    }

    statement {
      and_statement {
        statement {
          regex_match_statement {
            field_to_match {
              uri_path {}
            }
            regex_string = "^/v1/ephemeris$"   # Exactly /v1/ephemeris
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
          not_statement {
            statement {
              or_statement {

                statement {
                  byte_match_statement {
                    field_to_match {
                      single_header {
                        name = "content-type"
                      }
                    }
                    positional_constraint = "CONTAINS"
                    search_string         = "multipart/form-data"

                    text_transformation {
                      priority = 0
                      type     = "LOWERCASE"
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
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${replace(var.env_name, "-", "")}RestrictEphemeris"
      sampled_requests_enabled   = false
    }
  }

  # Content-Type and Body Size Restriction Rule
  rule {
    name     = "restrict-post-json-body-content-type"
    priority = 4

    action {
        block {
          custom_response {
            custom_response_body_key = "NOT_A_JSON"
            response_code            = 400
          }
        }
    }

    statement {
      and_statement {
        statement {
          regex_match_statement {
            field_to_match {
              uri_path {}
            }
            regex_string = "^/v1/(reentry-event-reports|analyses|conjunction-reports|manoeuvre_plots|tips)"  # Matches everything under /v1/
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
          not_statement {
            statement {
              or_statement {

                statement {
                  byte_match_statement {
                    field_to_match {
                      single_header {
                        name = "content-type"
                      }
                    }
                    positional_constraint = "CONTAINS"
                    search_string         = "multipart/form-data"

                    text_transformation {
                      priority = 0
                      type     = "LOWERCASE"
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
              }
            }
          }
        }


      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${replace(var.env_name, "-", "")}RestrictJsonContentType"
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