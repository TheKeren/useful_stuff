## Task definition will be one of four options: with volume and service role, without both or with just one of them :(

locals {
  container_to_override = "${length(local.container_names) == 1 ? local.container_names[0] : var.scheduled_task_container}"
  task_definition_arn   = "${concat(aws_ecs_task_definition.task-definition.*.arn, aws_ecs_task_definition.task-definition-vol.*.arn, 
                            aws_ecs_task_definition.task-definition-role.*.arn, aws_ecs_task_definition.task-definition-both.*.arn)}"

  enable_scheduled_task = "${var.scheduled_task_schedule_expression != "" ? 1 : 0 }"
}

resource "aws_cloudwatch_event_rule" "ecs_scheduled_task" {
  count               = "${local.enable_scheduled_task}"
  name                = "${local.branded_app_name}-scheduled_task"
  description         = "${local.branded_app_name}-scheduled_task"
  schedule_expression = "${var.scheduled_task_schedule_expression}"
}

resource "aws_cloudwatch_event_target" "ecs_scheduled_task" {
  count     = "${local.enable_scheduled_task}"
  target_id = "${local.branded_app_name}-scheduled_task"
  arn       = "${data.aws_ecs_cluster.ecs_cluster.arn}"
  rule      = "${aws_cloudwatch_event_rule.ecs_scheduled_task.name}"
  role_arn  = "${var.task_role_arn != "" ? var.task_role_arn : aws_iam_role.ecs-servicerole.arn}"

  ecs_target = {
    task_count          = 1
    task_definition_arn = "${local.task_definition_arn[0]}"
  }

  input = <<DOC
{
  "containerOverrides": [
    {
      "name": "${local.container_to_override}",
      "command": ["${join("\",\"", var.scheduled_task_command)}"]
    }
  ]
}
DOC
}
