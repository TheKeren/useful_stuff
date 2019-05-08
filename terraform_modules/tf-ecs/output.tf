output "instance_role_name" {
  value = "${aws_iam_role.ecs-admin.name}"
}

output "instance_role_arn" {
  value = "${aws_iam_role.ecs-admin.arn}"
}

output "ecs_cluster_sg_id" {
  value = "${aws_security_group.ecs-cluster.id}"
}

output "ecs_vpc_id" {
  value = "${var.vpc_id}"
}

output "ecs_id" {
  value = "${aws_ecs_cluster.ecs-cluster.id}"
}

output "ecs_arn" {
  value = "${aws_ecs_cluster.ecs-cluster.arn}"
}

output "ecs_name" {
  value = "${aws_ecs_cluster.ecs-cluster.name}"
}

output "ecs_admin_iam_role" {
  value = "${aws_iam_role.ecs-admin.name}"
}

output "efs_sg_id" {
  value = "${element(concat(aws_security_group.efs.*.id, list("")), 0)}"
}

output "efs_id" {
  value = "${element(concat(aws_efs_file_system.ecs_efs.*.id, list("")), 0)}"
}

output "brand_log_group_arn" {
  value = "${local.brand_log_group}"
}

output "launch_config_name" {
  value = "${aws_launch_configuration.ecs-cluster.name}"
}

output "ecs_ami_id" {
  value = "${data.aws_ami.ecs-ami-id.id}"
}

output "mem_high_alarm_action" {
  value = "${aws_autoscaling_policy.scale-ec2-up-mem.arn}"
}

output "cpu_high_alarm_action" {
  value = "${aws_autoscaling_policy.scale-ec2-up-cpu.arn}"
}
