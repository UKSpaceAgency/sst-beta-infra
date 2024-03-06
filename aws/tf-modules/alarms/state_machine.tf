resource "aws_cloudwatch_log_group" "state_machine_logs" {
  name              = "/ecs/state-machine-${var.env_name}"
  retention_in_days = 14
}

resource "aws_sfn_state_machine" "alarms_state_machine" {
  name     = "Alarms-State-Machine-${var.env_name}"
  role_arn = var.state_machine_role_arn
  publish  = true

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.state_machine_logs.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }

  definition = <<EOF
{
  "Comment": "A description of my state machine",
  "StartAt": "Pass",
  "States": {
    "Pass": {
      "Type": "Pass",
      "Next": "Lambda Invoke",
      "Parameters": {
        "alarmName.$": "$.detail.alarmName",
        "isRepeated": false,
        "currState.$": "$.detail.state.value"
      }
    },
    "Lambda Invoke": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "Parameters": {
        "Payload.$": "$",
        "FunctionName": "${var.notifications_sender_lambda_arn}:$LATEST"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException",
            "Lambda.TooManyRequestsException"
          ],
          "IntervalSeconds": 1,
          "MaxAttempts": 3,
          "BackoffRate": 2
        }
      ],
      "Next": "What is alarm's current state?",
      "ResultPath": null
    },
    "What is alarm's current state?": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.currState",
          "StringEquals": "ALARM",
          "Next": "Wait"
        }
      ],
      "Default": "Success"
    },
    "Success": {
      "Type": "Succeed"
    },
    "Wait": {
      "Type": "Wait",
      "Seconds": 43200,
      "Next": "DescribeAlarms"
    },
    "DescribeAlarms": {
      "Type": "Task",
      "Parameters": {
        "AlarmNames.$": "States.Array($.alarmName)"
      },
      "Resource": "arn:aws:states:::aws-sdk:cloudwatch:describeAlarms",
      "Next": "After wait, what is the alarm state?",
      "ResultSelector": {
        "alarmName.$": "$.MetricAlarms[0].AlarmName",
        "isRepeated": true,
        "currState.$": "$.MetricAlarms[0].StateValue"
      }
    },
    "After wait, what is the alarm state?": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.currState",
          "StringEquals": "ALARM",
          "Next": "Lambda Invoke"
        }
      ],
      "Default": "Success"
    }
  }
}
EOF
}