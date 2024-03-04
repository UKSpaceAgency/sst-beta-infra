resource "aws_cloudwatch_event_rule" "on_alarm_state_change" {
  name        = "on-alarm-state-change"
  description = "Subscribing alarm state change towards StateMachine"

  event_pattern = jsonencode({
    "source": ["aws.cloudwatch"],
    "detail-type": ["CloudWatch Alarm State Change"]
  })
}

resource "aws_cloudwatch_event_target" "target_to_state_machine" {
  target_id = "StateMachineTarget-${var.env_name}"
  rule      = aws_cloudwatch_event_rule.on_alarm_state_change.name
  arn       = aws_sfn_state_machine.alarms_state_machine.arn
  role_arn = var.event_bridge_iam_role_arn

}