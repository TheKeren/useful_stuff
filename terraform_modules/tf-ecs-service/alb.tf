locals {
  alb_enabled = "${var.enable_alb ? 1 : 0}"
}

resource "aws_lb" "front-end" {
  count           = "${local.alb_enabled}"
  name            = "${local.truncated_branded_app_name}-alb"
  internal        = "${var.internal_alb}"
  security_groups = ["${aws_security_group.alb-public.id}"]
  subnets         = ["${data.aws_subnet_ids.public.ids}"]

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.truncated_branded_app_name}-alb"
    )
  )}"
}

resource "aws_security_group" "alb-public" {
  count       = "${local.alb_enabled}"
  vpc_id      = "${var.ecs_vpc_id}"
  name_prefix = "${local.branded_app_name}"

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    protocol         = "-1"
    to_port          = 0
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.brand}-${lookup(local.common_tags,"component")}app-alb-sg"
    )
  )}"
}

locals {
  number_of_listner_ports = "${length(var.lb_listener_ports)}"
}

resource "aws_security_group_rule" "lb-listener" {
  count             = "${var.enable_alb ? local.number_of_listner_ports : 0}"
  type              = "ingress"
  from_port         = "${element(var.lb_listener_ports, count.index)}"
  to_port           = "${element(var.lb_listener_ports, count.index)}"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.alb-public.id}"
}
