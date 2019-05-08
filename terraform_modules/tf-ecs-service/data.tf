locals {
  ssm_branded_app_name = "${var.brand}-${var.app_name}"
  ssm_lookup_app_name  = "${var.ssm_lookup_app_name_override != "" ? var.ssm_lookup_app_name_override : local.ssm_branded_app_name}"
  subnet_lookup_tier   = "${var.internal_alb ? "private" : "public"}"
}

data "aws_caller_identity" "current" {}

data "aws_acm_certificate" "beamly_certificate" {
  count  = "${local.alb_enabled}"
  domain = "*.${var.route53_zone_name}"
}

data "aws_subnet_ids" "public" {
  vpc_id = "${var.ecs_vpc_id}"

  tags {
    tier = "${local.subnet_lookup_tier}"
  }
}

data "aws_ecs_cluster" "ecs_cluster" {
  cluster_name = "${var.ecs_name}"
}

data "aws_security_group" "ecs_cluster_sg" {
  id     = "${var.ecs_cluster_sg_id}"
  vpc_id = "${var.ecs_vpc_id}"
}

data "aws_ssm_parameter" "db_name" {
  name  = "${local.ssm_lookup_app_name}-${var.environment}-rds-db-name"
  count = "${var.ssm_rds_parameters ? 1 : 0}"
}

data "aws_ssm_parameter" "database_address" {
  name  = "${local.ssm_lookup_app_name}-${var.environment}-rds-database-address"
  count = "${var.ssm_rds_parameters ? 1 : 0}"
}

data "aws_ssm_parameter" "database_username" {
  name  = "${local.ssm_lookup_app_name}-${var.environment}-rds-username"
  count = "${var.ssm_rds_parameters ? 1 : 0}"
}

data "aws_ssm_parameter" "database_password" {
  name  = "${local.ssm_lookup_app_name}-${var.environment}-rds-password"
  count = "${var.ssm_rds_parameters ? 1 : 0}"
}

data "aws_ssm_parameter" "redis_url_frontend" {
  name  = "${local.ssm_lookup_app_name}-${var.environment}-redis-url"
  count = "${var.ssm_redis_frontend_parameters ? 1 : 0}"
}

data "aws_ssm_parameter" "redis_url_backend" {
  name  = "${local.ssm_lookup_app_name}-${var.environment}-redis-url"
  count = "${var.ssm_redis_backend_parameters ? 1 : 0}"
}
