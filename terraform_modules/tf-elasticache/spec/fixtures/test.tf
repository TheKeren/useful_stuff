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
  name        = "test-elasticache-placeholder-sg"
  description = "testing placeholder SG"
  vpc_id      = "${local.vpc_id}"
}

module "redis" {
  source                                  = "../.."
  app_name                                = "red-kitchen"
  engine                                  = "redis"
  environment                             = "${local.env}"
  brand                                   = "${local.brand}"
  stack                                   = "${local.stack}"
  vpc_id                                  = "${local.vpc_id}"
  num_cache_nodes                         = "2"
  maintenance_window                      = "sun:05:00-sun:09:00"
  apply_immediately                       = "true"
  total_number_of_inbound_security_groups = "1"
  ecs_cluster_sg_id                       = "${aws_security_group.placeholder.id}"
  snapshot_retention_limit                = "1"
}

module "memcached" {
  source                                  = "../.."
  app_name                                = "mem-kitchen"
  engine                                  = "memcached"
  environment                             = "${local.env}"
  brand                                   = "${local.brand}"
  stack                                   = "${local.stack}"
  vpc_id                                  = "${local.vpc_id}"
  preferred_availability_zones            = ["eu-central-1b"]
  total_number_of_inbound_security_groups = "1"
  ecs_cluster_sg_id                       = "${aws_security_group.placeholder.id}"
  snapshot_retention_limit                = "1"
}

module "redis-cluster" {
  source                                  = "../.."
  app_name                                = "red-cluster-kitchen"
  engine                                  = "redis"
  environment                             = "${local.env}"
  brand                                   = "${local.brand}"
  stack                                   = "${local.stack}"
  vpc_id                                  = "${local.vpc_id}"
  total_number_of_inbound_security_groups = "1"
  maintenance_window                      = "sun:05:00-sun:09:00"
  inbound_security_groups                 = ["${aws_security_group.placeholder.id}"]
  snapshot_retention_limit                = "1"
  redis_cluster_mode_num_node_groups      = "2"
}

output "redis_sg_id" {
  value = "${module.redis.elasticache_sg_id}"
}

output "redis_subnet_groups" {
  value = "${module.redis.elasticache_subnet_group_name}"
}

output "redis_endpoint" {
  value = "${module.redis.elasticache_endpoint}"
}

output "redis_cluster_endpoint" {
  value = "${module.redis-cluster.elasticache_endpoint}"
}

output "redis_id" {
  value = "${module.redis.elasticache_id}"
}

output "redis_cluster_sg_id" {
  value = "${module.redis-cluster.elasticache_sg_id}"
}

output "memcached_sg_id" {
  value = "${module.memcached.elasticache_sg_id}"
}

output "memcached_subnet_group" {
  value = "${module.memcached.elasticache_subnet_group_name}"
}

output "memcached_endpoint" {
  value = "${module.memcached.elasticache_endpoint}"
}

output "memcached_id" {
  value = "${module.memcached.elasticache_id}"
}

output "placeholder_sg_id" {
  value = "${aws_security_group.placeholder.id}"
}
