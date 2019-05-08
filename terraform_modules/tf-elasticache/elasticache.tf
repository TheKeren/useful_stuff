locals {
  branded_app_name = "${var.brand}-${var.app_name}-${var.environment}"

  common_tags = {
    environment = "${var.environment}"
    component   = "${var.app_name}"
    stack       = "${var.stack}"
    brand       = "${var.brand}"
    provisioner = "terraform"
  }

  truncated_app_name    = "${substr(var.app_name,         0, min(7,               length(var.app_name)))}"
  truncated_brand       = "${substr(var.brand,            0, min(7, length(var.brand)))}"
  truncated_environment = "${substr(var.environment,      0, min(5,               length(var.environment)))}"

  truncated_branded_app_name = "${local.truncated_brand}-${local.truncated_app_name}-${local.truncated_environment}"
}

data "aws_vpc" "vpc" {
  id = "${var.vpc_id}"
}

data "aws_subnet" "private" {
  count = "${length(var.azs)}"

  filter {
    name   = "tag:tier"
    values = ["private"]
  }

  vpc_id            = "${data.aws_vpc.vpc.id}"
  availability_zone = "${element(var.azs, count.index)}"
}

resource "aws_elasticache_subnet_group" "aws_elasticache_subnet_group" {
  name        = "${local.branded_app_name}-${var.engine}"
  description = "${local.branded_app_name}-${var.engine}-elasticache-subnet-group"
  subnet_ids  = ["${data.aws_subnet.private.*.id}"]
}

resource "aws_elasticache_cluster" "memcached" {
  count                        = "${var.engine == "memcached" ? 1 : 0}"
  cluster_id                   = "${local.truncated_branded_app_name}"
  engine                       = "${var.engine}"
  node_type                    = "${var.node_type}"
  num_cache_nodes              = "${var.num_cache_nodes}"
  parameter_group_name         = "${var.parameter_group_name == "" ? "default.memcached1.5" : var.parameter_group_name}"
  engine_version               = "${var.engine_version == "" ? "1.5.10" : var.engine_version}"
  port                         = "${var.port != "" ? var.port : "11211"}"
  maintenance_window           = "${var.maintenance_window}"
  subnet_group_name            = "${aws_elasticache_subnet_group.aws_elasticache_subnet_group.name}"
  security_group_ids           = ["${aws_security_group.elasticache.id}"]
  apply_immediately            = "${var.apply_immediately}"
  preferred_availability_zones = "${var.preferred_availability_zones}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.brand}-${lookup(local.common_tags,"component")}-memcached"
    )
  )}"
}

locals {
  is_redis      = "${var.engine == "redis" ? 1 : 0}"
  redis_cluster = "${var.redis_cluster_mode_num_node_groups != "" ? 1 : 0}"
}

resource "aws_elasticache_replication_group" "redis" {
  count                         = "${local.is_redis + local.redis_cluster == 1 ? 1 : 0}"
  automatic_failover_enabled    = "${var.automatic_failover}"
  availability_zones            = "${var.azs}"
  replication_group_id          = "${local.truncated_branded_app_name}"
  replication_group_description = "${local.branded_app_name}-redis"
  node_type                     = "${var.node_type}"
  number_cache_clusters         = "${var.num_cache_nodes}"
  parameter_group_name          = "${var.parameter_group_name == "" ? "default.redis5.0" : var.parameter_group_name}"
  auto_minor_version_upgrade    = "${var.auto_minor_version_upgrade}"
  availability_zones            = "${var.preferred_availability_zones}"
  engine_version                = "${var.engine_version == "" ? "5.0.0" : var.engine_version}"
  subnet_group_name             = "${aws_elasticache_subnet_group.aws_elasticache_subnet_group.name}"
  security_group_ids            = ["${aws_security_group.elasticache.id}"]
  port                          = "${var.port != "" ? var.port : "6379"}"
  maintenance_window            = "${var.maintenance_window}"
  snapshot_window               = "${var.snapshot_window}"
  snapshot_retention_limit      = "${var.snapshot_retention_limit}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.brand}-${lookup(local.common_tags,"component")}-redis"
    )
  )}"
}

resource "aws_elasticache_replication_group" "redis-cluster" {
  count                         = "${local.is_redis + local.redis_cluster == 2 ? 1 : 0}"
  replication_group_id          = "${local.truncated_branded_app_name}"
  replication_group_description = "${local.branded_app_name}-redis-cluster"
  node_type                     = "${var.node_type}"
  port                          = "${var.port != "" ? var.port : "6379"}"
  parameter_group_name          = "${var.parameter_group_name == "" ? "default.redis5.0.cluster.on" : var.parameter_group_name}"
  automatic_failover_enabled    = "true"
  auto_minor_version_upgrade    = "${var.auto_minor_version_upgrade}"
  availability_zones            = "${var.preferred_availability_zones}"
  engine_version                = "${var.engine_version == "" ? "5.0.0" : var.engine_version}"
  subnet_group_name             = "${aws_elasticache_subnet_group.aws_elasticache_subnet_group.name}"
  security_group_ids            = ["${aws_security_group.elasticache.id}"]
  maintenance_window            = "${var.maintenance_window}"
  snapshot_window               = "${var.snapshot_window}"
  snapshot_retention_limit      = "${var.snapshot_retention_limit}"

  cluster_mode {
    replicas_per_node_group = "${var.redis_cluster_mode_replicas_per_node_group}"
    num_node_groups         = "${var.redis_cluster_mode_num_node_groups}"
  }

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.brand}-${lookup(local.common_tags,"component")}-redis-cluster"
    )
  )}"
}
