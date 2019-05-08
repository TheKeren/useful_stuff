resource "aws_ssm_parameter" "redis_url" {
  name        = "${var.brand}-${var.app_name}-${var.environment}-${var.engine}-url"
  description = "The ${var.engine} endpoint for ${var.app_name} ${var.environment} environment"
  type        = "SecureString"
  value       = "${element(concat(aws_elasticache_replication_group.redis.*.primary_endpoint_address, aws_elasticache_replication_group.redis-cluster.*.configuration_endpoint_address, aws_elasticache_cluster.memcached.*.configuration_endpoint), 0)}"

  tags {
    environment = "${var.environment}"
  }
}
