resource "aws_appautoscaling_target" "ecs_service_scaling" {
  service_namespace  = "ecs"
  scalable_dimension = "ecs:service:DesiredCount"
  resource_id        = "service/mys-${var.env_name}/data-cache-client"

  min_capacity = 0   # allow scale-to-zero
  max_capacity = 1   # default
}

resource "aws_appautoscaling_policy" "scale_out" {
  name               = "ecs-scale-out-on-sqs"
  policy_type        = "StepScaling"
  service_namespace  = aws_appautoscaling_target.ecs_service_scaling.service_namespace
  resource_id        = aws_appautoscaling_target.ecs_service_scaling.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service_scaling.scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1  # add 1 task
    }
  }
}

resource "aws_appautoscaling_policy" "scale_in" {
  name               = "ecs-scale-in-on-empty-sqs"
  policy_type        = "StepScaling"
  service_namespace  = aws_appautoscaling_target.ecs_service_scaling.service_namespace
  resource_id        = aws_appautoscaling_target.ecs_service_scaling.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service_scaling.scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300  # 5 minutes cooldown to avoid flapping
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1 # remove 1 task
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "sqs_empty_5m" {
  alarm_name          = "sqs-empty-5min-scale-in-ecs"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 5          # 5 × 60s = 5 minutes
  threshold           = 0
  treat_missing_data  = "notBreaching"

  # This alarm is now based on metric math, so we use metric_query blocks
  # instead of top-level namespace/metric_name/statistic/period.

  # m1 = ApproximateNumberOfMessagesVisible (backlog)
  metric_query {
    id          = "m1"
    return_data = false

    metric {
      namespace   = "AWS/SQS"
      metric_name = "ApproximateNumberOfMessagesVisible"
      stat        = "Maximum"
      period      = 60

      dimensions = {
        QueueName = "data-cache-client-${var.env_name}"
      }
    }
  }

  # m2 = ApproximateNumberOfMessagesNotVisible (in-flight)
  metric_query {
    id          = "m2"
    return_data = false

    metric {
      namespace   = "AWS/SQS"
      metric_name = "ApproximateNumberOfMessagesNotVisible"
      stat        = "Maximum"
      period      = 60

      dimensions = {
        QueueName = "data-cache-client-${var.env_name}"
      }
    }
  }

  # e1 = m1 + m2  → total messages (waiting + in-flight)
  # Alarm when this stays == 0 for 10 minutes
  metric_query {
    id          = "e1"
    expression  = "m1 + m2"
    label       = "TotalMessagesVisibleAndNotVisible"
    return_data = true
  }

  alarm_actions = [
    aws_appautoscaling_policy.scale_in.arn
  ]
}

resource "aws_cloudwatch_metric_alarm" "sqs_has_messages" {
  alarm_name          = "sqs-has-messages-scale-out-ecs"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  statistic           = "Maximum"
  period              = 60             # 1 minute
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"

  dimensions = {
    QueueName = "data-cache-client-${var.env_name}"
  }

  alarm_actions = [
    aws_appautoscaling_policy.scale_out.arn
  ]
}