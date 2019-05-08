resource "aws_security_group" "ecs-cluster" {
  name   = "${local.full_name}"
  vpc_id = "${var.vpc_id}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.full_name}",
    )
  )}"
}

resource "aws_security_group_rule" "additional-sg" {
  count                    = "${var.number_of_additional_sg}"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.ecs-cluster.id}"
  to_port                  = 65535
  type                     = "ingress"
  source_security_group_id = "${element(var.additional_sg, count.index)}"
}

resource "aws_security_group_rule" "office-access" {
  from_port         = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.ecs-cluster.id}"
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = ["${var.office_ip}"]
}

resource "aws_security_group_rule" "all-out" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.ecs-cluster.id}"
  to_port           = 65535
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "egress"
}

resource "aws_security_group_rule" "all-out-ipv6" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.ecs-cluster.id}"
  to_port           = 65535
  ipv6_cidr_blocks  = ["::/0"]
  type              = "egress"
}

resource "aws_security_group_rule" "cluster-traffic" {
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.ecs-cluster.id}"
  source_security_group_id = "${aws_security_group.ecs-cluster.id}"
  to_port                  = 0
  type                     = "ingress"
}
