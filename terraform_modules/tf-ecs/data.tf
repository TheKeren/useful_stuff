data "aws_ami" "ecs-ami-id" {
  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  most_recent = true
  owners      = ["amazon"]
}

data "aws_caller_identity" "current" {}

data "aws_subnet_ids" "ecsagent-subnets" {
  vpc_id = "${var.vpc_id}"

  tags {
    tier = "${var.tier}"
  }
}
