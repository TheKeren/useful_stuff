output "alb-listener-arn" {
  value = "${aws_lb_listener.front-end.*.arn}"
}

output "ecs_service_iam_role" {
  value = "${element(concat(aws_ecs_service.ecs-service.*.iam_role, list("")), 0)}"
}

output "ecs_service_desired_count" {
  value = "${element(concat(aws_ecs_service.ecs-service.*.desired_count, aws_ecs_service.ecs-service-no-alb.*.desired_count), 0)}"
}

output "ecs_service_task_definition_arn" {
  value = "${element(concat(aws_ecs_task_definition.task-definition.*.arn, aws_ecs_task_definition.task-definition-vol.*.arn, 
                            aws_ecs_task_definition.task-definition-role.*.arn, aws_ecs_task_definition.task-definition-both.*.arn, aws_ecs_task_definition.task-definition-custom-role.*.arn), 0)}"
}

output "alb_security_group_id" {
  value = "${element(concat(aws_security_group.alb-public.*.id, list("")), 0)}"
}

output "alb_subnets" {
  value = "${flatten(aws_lb.front-end.*.subnets)}"
}

output "alb_arn" {
  value = "${element(concat(aws_lb.front-end.*.arn, list("")), 0)}"
}

output "alb_name" {
  value = "${element(concat(aws_lb.front-end.*.name, list("")), 0)}"
}

output "listener_cert" {
  value = "${element(concat(data.aws_acm_certificate.beamly_certificate.*.arn, list("")), 0)}"
}

output "alb_target_group_arn" {
  value = "${element(concat(aws_lb_target_group.target_group.*.arn, list("")), 0)}"
}
