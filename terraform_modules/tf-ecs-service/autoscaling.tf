resource "aws_appautoscaling_target" "app-autoscaling-target" {
  max_capacity       = "${var.autoscaling_max_capacity}"
  min_capacity       = "${var.autoscaling_min_capacity}"
  resource_id        = "service/${var.ecs_name}/${element(concat(aws_ecs_service.ecs-service.*.name, aws_ecs_service.ecs-service-no-alb.*.name), 0)}"
  role_arn           = "${aws_iam_role.app-ast-servicerole.arn}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu-autoscaling-up" {
  name               = "${local.branded_app_name}-cpu-up"
  resource_id        = "service/${var.ecs_name}/${element(concat(aws_ecs_service.ecs-service.*.name, aws_ecs_service.ecs-service-no-alb.*.name), 0)}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 15
    metric_aggregation_type = "Average"

    step_adjustment {
      scaling_adjustment          = 1
      metric_interval_lower_bound = 0.0
      metric_interval_upper_bound = 25.0
    }

    step_adjustment {
      scaling_adjustment          = 2
      metric_interval_lower_bound = 25.0
    }
  }

  depends_on = ["aws_appautoscaling_target.app-autoscaling-target"]
}

resource "aws_appautoscaling_policy" "cpu-autoscaling-down" {
  name               = "${local.branded_app_name}-cpu-down"
  resource_id        = "service/${var.ecs_name}/${element(concat(aws_ecs_service.ecs-service.*.name, aws_ecs_service.ecs-service-no-alb.*.name), 0)}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 15
    metric_aggregation_type = "Average"

    step_adjustment {
      scaling_adjustment          = -1
      metric_interval_upper_bound = 0.0
    }
  }

  depends_on = ["aws_appautoscaling_target.app-autoscaling-target"]
}

resource "aws_appautoscaling_policy" "mem-autoscaling-up" {
  name               = "${local.branded_app_name}-mem-up"
  resource_id        = "service/${var.ecs_name}/${element(concat(aws_ecs_service.ecs-service.*.name, aws_ecs_service.ecs-service-no-alb.*.name), 0)}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 15
    metric_aggregation_type = "Average"

    step_adjustment {
      scaling_adjustment          = 1
      metric_interval_lower_bound = 0.0
      metric_interval_upper_bound = 25.0
    }

    step_adjustment {
      scaling_adjustment          = 2
      metric_interval_lower_bound = 25.0
    }
  }

  depends_on = ["aws_appautoscaling_target.app-autoscaling-target"]
}

resource "aws_appautoscaling_policy" "mem-autoscaling-down" {
  name               = "${local.branded_app_name}-mem-down"
  resource_id        = "service/${var.ecs_name}/${element(concat(aws_ecs_service.ecs-service.*.name, aws_ecs_service.ecs-service-no-alb.*.name), 0)}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 15
    metric_aggregation_type = "Average"

    step_adjustment {
      scaling_adjustment          = -1
      metric_interval_upper_bound = 0.0
    }
  }

  depends_on = ["aws_appautoscaling_target.app-autoscaling-target"]
}

resource "aws_cloudwatch_metric_alarm" "cloudwatch-scaleup-cpu" {
  alarm_name          = "${local.branded_app_name}-cpu-up"
  alarm_description   = "This alarm monitors '${var.ecs_name}' ECS CPU Utilisation for scaling up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = "${var.autoscaling_cpu_up_threshold}"
  alarm_actions       = ["${aws_appautoscaling_policy.cpu-autoscaling-up.arn}"]

  dimensions {
    ClusterName = "${var.ecs_name}"
    ServiceName = "${element(concat(aws_ecs_service.ecs-service.*.name, aws_ecs_service.ecs-service-no-alb.*.name), 0)}"
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudwatch-scaledown-cpu" {
  alarm_name          = "${local.branded_app_name}-cpu-down"
  alarm_description   = "This alarm monitors '${var.ecs_name}' ECS CPU Utilisation for scaling down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 5
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = "${var.autoscaling_cpu_down_threshold}"
  alarm_actions       = ["${aws_appautoscaling_policy.cpu-autoscaling-down.arn}"]

  dimensions {
    ClusterName = "${var.ecs_name}"
    ServiceName = "${element(concat(aws_ecs_service.ecs-service.*.name, aws_ecs_service.ecs-service-no-alb.*.name), 0)}"
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudwatch-scaleup-mem" {
  alarm_name          = "${local.branded_app_name}-mem-up"
  alarm_description   = "This alarm monitors '${var.ecs_name}' ECS Memory Utilisation for scaling up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = "${var.autoscaling_mem_up_threshold}"
  alarm_actions       = ["${aws_appautoscaling_policy.mem-autoscaling-up.arn}"]

  dimensions {
    ClusterName = "${var.ecs_name}"
    ServiceName = "${element(concat(aws_ecs_service.ecs-service.*.name, aws_ecs_service.ecs-service-no-alb.*.name), 0)}"
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudwatch-scaledown-mem" {
  alarm_name          = "${local.branded_app_name}-mem-down"
  alarm_description   = "This alarm monitors '${var.ecs_name}' ECS Memory Utilisation for scaling down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 5
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = "${var.autoscaling_mem_down_threshold}"
  alarm_actions       = ["${aws_appautoscaling_policy.mem-autoscaling-down.arn}"]

  dimensions {
    ClusterName = "${var.ecs_name}"
    ServiceName = "${element(concat(aws_ecs_service.ecs-service.*.name, aws_ecs_service.ecs-service-no-alb.*.name), 0)}"
  }
}
