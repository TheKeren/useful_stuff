terraform {
  backend "s3" {}
}

provider "aws" {
  region = "${local.region}"

  assume_role {
    role_arn     = "${var.test_role}"
    session_name = "kitchen-terraform"
  }
}

variable "test_role" {
  default = "arn:aws:iam::011881316557:role/rd-terraform-provisioner"
}

locals {
  vpc_id = "vpc-0770690a74d72f5e1" // infrastructure-testing vpc in rd aws account
  env    = "test"
  brand  = "platform"
  stack  = "kitchen-terraform"
  region = "eu-central-1"
}

resource "aws_security_group" "placeholder" {
  name        = "test-placeholder-sg"
  description = "Security group for the EFS"
  vpc_id      = "${local.vpc_id}"
}

module "ecs" {
  source                 = "../.."
  project_name           = "kitchen"
  asg_max_size           = 4
  asg_min_size           = 2
  cluster_instance_sizes = "t2.micro"
  key_name               = "terraform_test"
  region                 = "${local.region}"
  environment            = "${local.env}"
  brand                  = "${local.brand}"
  branch                 = "master"
  stack                  = "${local.stack}"
  create_efs             = true
  vpc_id                 = "${local.vpc_id}"
  additional_sg          = ["${aws_security_group.placeholder.id}"]
}

output "instance_role_name" {
  value = "${module.ecs.instance_role_name}"
}

output "instance_role_arn" {
  value = "${module.ecs.instance_role_arn}"
}

output "ecs_cluster_sg_id" {
  value = "${module.ecs.ecs_cluster_sg_id}"
}

output "ecs_id" {
  value = "${module.ecs.ecs_id}"
}

output "ecs_name" {
  value = "${module.ecs.ecs_name}"
}

output "placeholder_sg_id" {
  value = "${aws_security_group.placeholder.id}"
}

output "efs_sg_id" {
  value = "${module.ecs.efs_sg_id}"
}

output "efs_id" {
  value = "${module.ecs.efs_id}"
}

output "brand_log_group_arn" {
  value = "${module.ecs.brand_log_group_arn}"
}

output "launch_config_name" {
  value = "${module.ecs.launch_config_name}"
}

output "ecs_ami_id" {
  value = "${module.ecs.ecs_ami_id}"
}

output "mem_high_alarm_action" {
  value = "${module.ecs.mem_high_alarm_action}"
}

output "cpu_high_alarm_action" {
  value = "${module.ecs.cpu_high_alarm_action}"
}
