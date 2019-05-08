resource "aws_efs_file_system" "ecs_efs" {
  count          = "${var.create_efs ? 1 : 0}"
  creation_token = "${local.full_name}-ecs"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.full_name}-efs",
      "component", "ecs-efs-volume"
    )
  )}"
}

resource "aws_efs_mount_target" "mount_target" {
  count           = "${var.create_efs ? length(data.aws_subnet_ids.ecsagent-subnets.ids) : 0}"
  file_system_id  = "${aws_efs_file_system.ecs_efs.id}"
  subnet_id       = "${element(data.aws_subnet_ids.ecsagent-subnets.ids, count.index)}"
  security_groups = ["${aws_security_group.efs.id}"]
}

data "template_file" "launch_config_efs" {
  count = "${var.create_efs ? 1 : 0}"

  template = <<USERDATA
#!/bin/bash
echo ECS_CLUSTER=$${clusterName} >> /etc/ecs/ecs.config
sudo yum install -y amazon-efs-utils
sudo stop ecs
sudo mkdir $${efsMountPoint}
sudo chmod 777 $${efsMountPoint}
sudo mount -t efs $${efsId}:/ $${efsMountPoint}
sudo service docker restart
sudo start ecs
USERDATA

  vars {
    clusterName   = "${aws_ecs_cluster.ecs-cluster.name}"
    efsId         = "${aws_efs_file_system.ecs_efs.id}"
    efsMountPoint = "/home/ec2-user/efs"
  }
}

resource "aws_security_group" "efs" {
  count       = "${var.create_efs ? 1 : 0}"
  name        = "${local.full_name}-efs"
  description = "Security group for the EFS"
  vpc_id      = "${var.vpc_id}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.full_name}-efs",
    )
  )}"
}

resource "aws_security_group_rule" "allow_all" {
  count                    = "${var.create_efs ? 1 : 0}"
  type                     = "ingress"
  security_group_id        = "${aws_security_group.efs.id}"
  source_security_group_id = "${aws_security_group.ecs-cluster.id}"
  protocol                 = "tcp"
  from_port                = 2049
  to_port                  = 2049
}
