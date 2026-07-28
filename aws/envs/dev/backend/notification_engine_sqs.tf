resource "aws_sqs_queue" "notification_engine_events_dlq" {
  name                      = "notification-engine-events-dlq-${var.env_name}"
  message_retention_seconds = 1209600 # 14 days
}

resource "aws_sqs_queue" "notification_engine_events" {
  name                       = "notification-engine-events-${var.env_name}"
  message_retention_seconds  = 1209600
  visibility_timeout_seconds = 900

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.notification_engine_events_dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue" "notification_engine_delivery_dlq" {
  name                      = "notification-engine-delivery-dlq-${var.env_name}"
  message_retention_seconds = 1209600
}

resource "aws_sqs_queue" "notification_engine_delivery" {
  name                       = "notification-engine-delivery-${var.env_name}"
  message_retention_seconds  = 1209600
  visibility_timeout_seconds = 900

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.notification_engine_delivery_dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_iam_role_policy" "ecs_publish_notification_engine_events" {
  name = "ecs-publish-notification-engine-events"
  role = "ecs-task-role-for-${var.env_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["sqs:SendMessage"]
        Resource = [aws_sqs_queue.notification_engine_events.arn]
      }
    ]
  })
}
