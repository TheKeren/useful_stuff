resource "aws_security_group" "elasticache" {
  name   = "${local.branded_app_name}"
  vpc_id = "${var.vpc_id}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.branded_app_name}",
    )
  )}"
}

locals {
  inbound_security_groups = "${concat(compact(list(var.ecs_cluster_sg_id)), var.inbound_security_groups)}"
}

resource "aws_security_group_rule" "inbound-sg" {
  count                    = "${var.total_number_of_inbound_security_groups}"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.elasticache.id}"
  to_port                  = 65535
  type                     = "ingress"
  source_security_group_id = "${element(local.inbound_security_groups, count.index)}"
}

resource "aws_security_group_rule" "all-out" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.elasticache.id}"
  to_port           = 65535
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "egress"
}

resource "aws_security_group_rule" "cluster-traffic" {
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.elasticache.id}"
  source_security_group_id = "${aws_security_group.elasticache.id}"
  to_port                  = 0
  type                     = "ingress"
}
