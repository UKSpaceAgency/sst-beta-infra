module "alarms_stack" {
  source                          = "../../../tf-modules/alarms"
  env_name                        = var.env_name
  cluster_log_group_name          = data.terraform_remote_state.stack.outputs.cluster_log_group_name
  notifications_sender_lambda_arn = module.notifications_sender_lambda.public_lambda_arn
  state_machine_role_arn          = data.terraform_remote_state.stack.outputs.state_machine_iam_role_arn
  event_bridge_iam_role_arn       =  data.terraform_remote_state.stack.outputs.event_bridge_iam_role_arn
}