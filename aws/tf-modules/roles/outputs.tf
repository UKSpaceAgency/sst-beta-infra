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

output "lambda_iam_policy_vpc_arn" {
  value = aws_iam_policy.lambda-iam-policy-vpc.arn
}

output "lambda_iam_policy_public_arn" {
  value = aws_iam_policy.lambda-iam-policy-public.arn
}

output "lambda_vpc_iam_role_name" {
  value = aws_iam_role.lambda-assume-role-vpc.name
}

output "lambda_vpc_iam_role_arn" {
  value = aws_iam_role.lambda-assume-role-vpc.arn
}

output "lambda_public_iam_role_name" {
  value = aws_iam_role.lambda-assume-role-public.name
}

output "lambda_public_iam_role_arn" {
  value = aws_iam_role.lambda-assume-role-public.arn
}

output "state_machine_iam_role_arn" {
  value = aws_iam_role.state_machine_role.arn
}

output "event_bridge_invoke_sfn_iam_role_arn" {
  value = aws_iam_role.event_bridge_invoke_sfn_iam_role.arn
}