locals {
  # Strip feature/ hotfix/ name/ etc. prefix
  branch_suffix = "${replace(var.branch, "/.*\\//", "")}"

  # Remove non-alphanumeric chars
  cleaned_branch = "${replace(local.branch_suffix, "/[^a-zA-Z0-9]/", "")}"

  full_branch_part = "${ var.branch == "master" ? "" : "-${local.cleaned_branch}" }"

  full_name = "${var.project_name}-${var.brand}-${var.environment}${local.full_branch_part}"

  common_tags = {
    environment = "${var.environment}"
    stack       = "tf-ecs"
    brand       = "${var.brand}"
    provisioner = "terraform"
    branch      = "${var.branch}"
    vendor      = "${var.project_name}"
  }
}

resource "aws_ecs_cluster" "ecs-cluster" {
  name = "${local.full_name}"
}

resource "aws_autoscaling_group" "ecs-cluster" {
  name                 = "${local.full_name}"
  launch_configuration = "${aws_launch_configuration.ecs-cluster.name}"
  max_size             = "${var.asg_max_size}"
  min_size             = "${var.asg_min_size}"
  vpc_zone_identifier  = ["${data.aws_subnet_ids.ecsagent-subnets.ids}"]

  tags = [
    {
      key                 = "Name"
      value               = "${local.full_name}"
      propagate_at_launch = true
    },
    {
      key                 = "environment"
      value               = "${lookup(local.common_tags, "environment")}"
      propagate_at_launch = true
    },
    {
      key                 = "stack"
      value               = "${lookup(local.common_tags, "stack")}"
      propagate_at_launch = true
    },
    {
      key                 = "brand"
      value               = "${lookup(local.common_tags, "brand")}"
      propagate_at_launch = true
    },
    {
      key                 = "provisioner"
      value               = "${lookup(local.common_tags, "provisioner")}"
      propagate_at_launch = true
    },
    {
      key                 = "branch"
      value               = "${lookup(local.common_tags, "branch")}"
      propagate_at_launch = true
    },
    {
      key                 = "vendor"
      value               = "${lookup(local.common_tags, "vendor")}"
      propagate_at_launch = true
    },
  ]
}

data "template_file" "launch_config" {
  count = "${var.create_efs ? 0 : 1}"

  template = <<USERDATA
#!/bin/bash
echo ECS_CLUSTER=$${clusterName} >> /etc/ecs/ecs.config
USERDATA

  vars {
    clusterName = "${aws_ecs_cluster.ecs-cluster.name}"
  }
}

locals {
  efs_user_data = "${element(concat(data.template_file.launch_config_efs.*.rendered, list("")) ,0)}"
  user_data     = "${element(concat(data.template_file.launch_config.*.rendered, list("")) ,0)}"
}

resource "aws_launch_configuration" "ecs-cluster" {
  name_prefix          = "${local.full_name}-"
  image_id             = "${data.aws_ami.ecs-ami-id.id}"
  instance_type        = "${var.cluster_instance_sizes}"
  iam_instance_profile = "${aws_iam_instance_profile.ecs-admin.name}"
  key_name             = "${var.key_name}"
  security_groups      = ["${aws_security_group.ecs-cluster.id}"]
  user_data            = "${var.create_efs ? local.efs_user_data : local.user_data}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "scale-ec2-up-cpu" {
  name                   = "${local.full_name}-scaleup-cpu"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.ecs-cluster.name}"
}

resource "aws_autoscaling_policy" "scale-ec2-up-mem" {
  name                   = "${local.full_name}-scaleup-mem"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.ecs-cluster.name}"
}

resource "aws_cloudwatch_metric_alarm" "cpu-high" {
  alarm_name          = "${local.full_name}-cpu-high"
  alarm_description   = "This alarm monitors '${aws_ecs_cluster.ecs-cluster.name}' EC2 CPU Utilisation for scaling up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Maximum"
  threshold           = 80

  alarm_actions = [
    "${aws_autoscaling_policy.scale-ec2-up-cpu.arn}",
  ]

  dimensions {
    ClusterName = "${aws_ecs_cluster.ecs-cluster.name}"
  }
}

resource "aws_cloudwatch_metric_alarm" "mem-high" {
  alarm_name          = "${local.full_name}-scaleup-ecs_mem"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryReservation"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Maximum"
  threshold           = 70

  alarm_actions = [
    "${aws_autoscaling_policy.scale-ec2-up-mem.arn}",
  ]

  dimensions {
    ClusterName = "${aws_ecs_cluster.ecs-cluster.name}"
  }
}
