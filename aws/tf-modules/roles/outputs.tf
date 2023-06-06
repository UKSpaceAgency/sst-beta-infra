output "ecs_execution_role_arn" {
  value = aws_iam_role.ecs-execution-role.arn
}

output "ecs_task_role_arn" {
  value = aws_iam_role.ecs-task-role.arn
}

output "ecs_events_role_arn" {
  value = aws_iam_role.ecs_events.arn
}

output "ecs_events_role_id" {
  value = aws_iam_role.ecs_events.id
}