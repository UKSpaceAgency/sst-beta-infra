module "data_cache_client" {
  source                 = "../../../tf-modules/ecsapp_no_sc"
  env_name               = var.env_name
  alb_name               = data.terraform_remote_state.stack.outputs.alb_name
  app_alb_priority       = 15
  app_cpu                = 512
  app_instances_num      = 1
  app_mem                = 1024
  app_name               = "data-cache-client"
  ecr_app_name           = "backend"
  app_port_num           = 8080
  default_capacity_provider = "FARGATE_SPOT"
  awslogs_group          = data.terraform_remote_state.stack.outputs.cluster_log_group_name
  custom_vpc_id          = data.terraform_remote_state.stack.outputs.custom_vpc_id
  default_sg_id          = data.terraform_remote_state.stack.outputs.default_sg_id
  ecs_cluster_arn        = data.terraform_remote_state.stack.outputs.cluster_arn
  ecs_execution_role_arn = data.terraform_remote_state.stack.outputs.ecs_execution_role_arn
  ecs_task_role_arn      = data.terraform_remote_state.stack.outputs.ecs_task_role_arn
  public_subnet_ids      = data.terraform_remote_state.stack.outputs.public_subnet_ids
  custom_command = ["poetry", "run", "uvicorn", "--host=0.0.0.0", "--port=8080", "app.cache_consumer.main:app", "--workers", "1"]
  env_vars = [
    { "name" : "APP_NAME", "value" : "Data Cache Client (${var.image_tag})" },
    { "name" : "APP_ENVIRONMENT", "value" : var.env_name },
    { "name" : "S3_SQS_QUEUE_ARN", "value" : var.data_cache_sqs_arn },
  ]
  secret_env_vars = [
    {
      "name" : "DATABASE_URL",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:databaseUrl::"
    },
    {
      "name" : "HASHID_SALT",
      "valueFrom" : "${data.aws_secretsmanager_secret.by-name.arn}:hashSaltId::"
    }
  ]
  healthcheck_subpath = "/healthcheck"
  image_tag           = var.image_tag
  route53_domain      = local.local_r53_domain
  enable_ecs_execute  = true
}

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
