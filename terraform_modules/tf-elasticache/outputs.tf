output "elasticache_id" {
  value = "${element(concat(aws_elasticache_cluster.memcached.*.cluster_id, aws_elasticache_replication_group.redis.*.id, aws_elasticache_replication_group.redis-cluster.*.id), 0)}"
}

output "elasticache_endpoint" {
  value = "${element(concat(aws_elasticache_cluster.memcached.*.configuration_endpoint, aws_elasticache_replication_group.redis.*.primary_endpoint_address, aws_elasticache_replication_group.redis-cluster.*.configuration_endpoint_address), 0)}"
}

output "elasticache_sg_id" {
  value = "${aws_security_group.elasticache.id}"
}

output "elasticache_subnet_group_name" {
  value = "${aws_elasticache_subnet_group.aws_elasticache_subnet_group.name}"
}
