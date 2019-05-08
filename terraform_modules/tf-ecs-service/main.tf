locals {
  common_tags = {
    environment = "${var.environment}"
    component   = "${var.app_name}"
    stack       = "${var.stack}"
    brand       = "${var.brand}"
    branch      = "${var.branch}"
    provisioner = "terraform"
  }

  # Strip feature/ hotfix/ name/ etc. prefix
  branch_suffix = "${replace(var.branch, "/.*\\//", "")}"

  # Remove non-alphanumeric chars
  cleaned_branch = "${replace(local.branch_suffix, "/[^a-zA-Z0-9]/", "")}"

  branch_part = "${ var.branch == "master" ? "" : "-${local.cleaned_branch}" }"

  branded_app_name = "${var.brand}-${var.app_name}-${var.environment}${local.branch_part}"

  td_volume_enabled = "${lookup(var.volume_definition, "volume_name") == "" ? 0 : 1}"

  brandsize = "${var.branch == "master" ? 11 : 7 }"

  truncated_app_name    = "${substr(var.app_name,         0, min(7,               length(var.app_name)))}"
  truncated_brand       = "${substr(var.brand,            0, min(local.brandsize, length(var.brand)))}"
  truncated_environment = "${substr(var.environment,      0, min(4,               length(var.environment)))}"
  truncated_branch      = "${substr(local.cleaned_branch, 0, min(4,               length(local.cleaned_branch)))}"

  truncated_branch_part = "${ var.branch == "master" ? "" : "-${local.truncated_branch}" }"

  truncated_branded_app_name = "${local.truncated_brand}-${local.truncated_app_name}-${local.truncated_environment}${local.truncated_branch_part}"

  task_role_enabled = "${var.task_role_arn == "" ? 0 : 1}"
}

## Task definition will be one of four options: with volume and service role, without both or with just one of them :( 

resource "aws_ecs_task_definition" "task-definition" {
  count                 = "${local.task_role_enabled == 0 && local.td_volume_enabled + local.extra_policy_count == 0? 1 : 0}"
  family                = "${local.branded_app_name}"
  container_definitions = "${data.template_file.td_wrapper.rendered}"
}

resource "aws_ecs_task_definition" "task-definition-role" {
  count                 = "${local.task_role_enabled == 0 && local.td_volume_enabled + local.extra_policy_count == 1? local.extra_policy_count : 0}"
  family                = "${local.branded_app_name}"
  container_definitions = "${data.template_file.td_wrapper.rendered}"
  task_role_arn         = "${aws_iam_role.task-definition-servicerole.arn}"
  execution_role_arn    = "${aws_iam_role.task-definition-servicerole.arn}"
}

resource "aws_ecs_task_definition" "task-definition-vol" {
  count                 = "${local.task_role_enabled == 0 && local.td_volume_enabled + local.extra_policy_count == 1? local.td_volume_enabled : 0}"
  family                = "${local.branded_app_name}"
  container_definitions = "${data.template_file.td_wrapper.rendered}"

  volume {
    name      = "${lookup(var.volume_definition, "volume_name")}"
    host_path = "${lookup(var.volume_definition, "host_path")}"
  }
}

resource "aws_ecs_task_definition" "task-definition-both" {
  count                 = "${local.task_role_enabled == 0 && local.td_volume_enabled + local.extra_policy_count == 2? 1 : 0}"
  family                = "${local.branded_app_name}"
  container_definitions = "${data.template_file.td_wrapper.rendered}"
  task_role_arn         = "${aws_iam_role.task-definition-servicerole.arn}"
  execution_role_arn    = "${aws_iam_role.task-definition-servicerole.arn}"

  volume {
    name      = "${lookup(var.volume_definition, "volume_name")}"
    host_path = "${lookup(var.volume_definition, "host_path")}"
  }
}

resource "aws_ecs_task_definition" "task-definition-custom-role" {
  count                 = "${local.task_role_enabled}"
  family                = "${local.branded_app_name}"
  container_definitions = "${data.template_file.td_wrapper.rendered}"
  task_role_arn         = "${var.task_role_arn}"

  volume {
    name      = "${lookup(var.volume_definition, "volume_name")}"
    host_path = "${lookup(var.volume_definition, "host_path")}"
  }
}

locals {
  td_family = "${element(concat(aws_ecs_task_definition.task-definition.*.family, aws_ecs_task_definition.task-definition-vol.*.family, 
                        aws_ecs_task_definition.task-definition-role.*.family, aws_ecs_task_definition.task-definition-both.*.family, aws_ecs_task_definition.task-definition-custom-role.*.family), 0)}"

  td_revision = "${element(concat(aws_ecs_task_definition.task-definition.*.revision, aws_ecs_task_definition.task-definition-vol.*.revision, 
                        aws_ecs_task_definition.task-definition-role.*.revision, aws_ecs_task_definition.task-definition-both.*.revision, aws_ecs_task_definition.task-definition-custom-role.*.revision), 0)}"
}

resource "aws_ecs_service" "ecs-service" {
  count                              = "${local.alb_enabled}"
  name                               = "${local.branded_app_name}"
  cluster                            = "${data.aws_ecs_cluster.ecs_cluster.arn}"
  task_definition                    = "${local.td_family}:${local.td_revision}"
  desired_count                      = "${var.task_count}"
  deployment_minimum_healthy_percent = "50"
  deployment_maximum_percent         = "100"
  iam_role                           = "${aws_iam_role.ecs-servicerole.arn}"
  health_check_grace_period_seconds  = "${var.health_check_grace_period_seconds}"

  load_balancer {
    target_group_arn = "${aws_lb_target_group.target_group.arn}"
    container_name   = "${var.frontend_container_name}"          # nginx container
    container_port   = "${var.frontend_container_port}"          # nginx port
  }

  lifecycle {
    ignore_changes = ["desired_count"]
  }
}

resource "aws_ecs_service" "ecs-service-no-alb" {
  count                              = "${var.enable_alb ? 0 : 1}"
  name                               = "${local.branded_app_name}"
  cluster                            = "${data.aws_ecs_cluster.ecs_cluster.arn}"
  task_definition                    = "${local.td_family}:${local.td_revision}"
  desired_count                      = "${var.task_count}"
  deployment_minimum_healthy_percent = "50"
  deployment_maximum_percent         = "100"

  lifecycle {
    ignore_changes = ["desired_count"]
  }
}

resource "aws_lb_target_group" "target_group" {
  count                = "${local.alb_enabled}"
  name                 = "${local.truncated_branded_app_name}-lb-tg"
  port                 = "${var.frontend_container_port}"
  protocol             = "HTTP"
  vpc_id               = "${var.ecs_vpc_id}"
  deregistration_delay = "30"
  depends_on           = ["aws_lb.front-end"]

  health_check {
    interval = 60
    path     = "${var.healthcheck_path}"
    matcher  = "${var.healthcheck_matcher}"
  }

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.brand}-${lookup(local.common_tags,"component")}app-ecs-target_group"
    )
  )}"
}

resource "aws_lb_listener" "front-end" {
  count             = "${var.enable_alb ? local.number_of_listner_ports : 0}"
  load_balancer_arn = "${aws_lb.front-end.arn}"
  port              = "${element(var.lb_listener_ports, count.index)}"

  protocol        = "HTTPS"
  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = "${data.aws_acm_certificate.beamly_certificate.arn}"

  default_action {
    target_group_arn = "${aws_lb_target_group.target_group.arn}"
    type             = "forward"
  }
}

resource "aws_security_group_rule" "alb-to-ecs" {
  count                    = "${local.alb_enabled}"
  from_port                = 0
  protocol                 = "tcp"
  security_group_id        = "${data.aws_security_group.ecs_cluster_sg.id}"
  source_security_group_id = "${aws_security_group.alb-public.id}"
  to_port                  = 65535
  type                     = "ingress"
  description              = "Allow access to ${lookup(local.common_tags,"component")}-${var.brand}-alb"
}

module "logs" {
  source = "github.com/zeebox/tf-logs"

  application   = "${var.brand}/${var.app_name}"
  environment   = "${var.environment}"
  branch        = "${var.branch}"
  region        = "${var.region}"
  team          = "platform"
  vendor        = "coty"
  enable_module = "${var.enable_logs}"
}

locals {
  log_branch     = "${var.branch == "master" ? "" : ".${var.branch}"}"
  log_group_name = "/coty/platform/${var.brand}/${var.app_name}${local.log_branch}/${var.environment}"
}

resource "aws_cloudwatch_log_group" "log_group" {
  count = "${var.enable_logs? 0 : 1}"
  name  = "${local.log_group_name}"

  tags {
    Vendor      = "coty"
    Team        = "platform"
    Environment = "${var.environment}"
    Application = "${var.brand}/${var.app_name}"
    Branch      = "${var.branch}"
    Provisioner = "terraform"
  }
}
