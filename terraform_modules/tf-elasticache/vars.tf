variable "stack" {}
variable "environment" {}
variable "brand" {}
variable "app_name" {}

variable "vpc_id" {
  description = "The vpc ID for the VPC in which the elasticache cluster will be created"
}

variable "total_number_of_inbound_security_groups" {
  description = "The total number security groups (inbound + ecs_cluster vars), used as the value of count"
  default     = "0"
}

variable "inbound_security_groups" {
  description = "IDs of other SG that will need to allow traffic to the cluster, i.e ecs"
  type        = "list"
  default     = []
}

variable "ecs_cluster_sg_id" {
  description = "ID of ecs-cluster sg. Only needed to allow module chaning via GoCD"
  default     = ""
}

variable "engine" {
  description = "Elasticache engine, should be 'redis' or 'memcached'"
}

variable "engine_version" {
  description = "Elasticache engine version, defaults to '1.5.10' for memcached and '5.0.0' for redis"
  default     = ""
}

variable "node_type" {
  description = "Elasticache node type, that should be used for the cluster"
  default     = "cache.t2.micro"
}

variable "num_cache_nodes" {
  description = "Not used for redis-cluster mode. Number of cache nodes (primary + replica for redis), accepted values: memcache 1-20, redis 1-5"
  default     = "1"
}

variable "parameter_group_name" {
  description = "Elasticache parameter group to use for the cluster, defaults to 'default.redis5.0' for redis and 'default.memcached1.5' for memcache"
  default     = ""
}

variable "port" {
  description = "Port number for the cluster, defaults to '11211' for memcached and '6379' for redis"
  default     = ""
}

variable "maintenance_window" {
  description = "Specifies the weekly time range for when maintenance on the cache cluster is performed. The format is ddd:hh24:mi-ddd:hh24:mi (24H Clock UTC). The minimum maintenance window is a 60 minute period. Example: sun:05:00-sun:09:00"
  default     = ""
}

variable "apply_immediately" {
  description = "If set to 'true' changes to the cluster will be applied immidiatly, otherwise, they will be applied during the next maintenane window"
  default     = false
}

variable "preferred_availability_zones" {
  description = "A list of the Availability Zones in which cache nodes are created. The number of Availability Zones listed must equal the value of num_cache_nodes"
  type        = "list"
  default     = []
}

variable "snapshot_window" {
  description = "Redis only. The daily time range (in UTC) during which ElastiCache will begin taking a daily snapshot of your cache cluster. Example: 05:00-09:00"
  default     = ""
}

variable "snapshot_retention_limit" {
  description = "Redis only. The number of days for which ElastiCache will retain automatic cache cluster snapshots before deleting them. If the value of SnapshotRetentionLimit is set to zero (0), backups are turned off"
  default     = "0"
}

variable "automatic_failover" {
  description = "Redis only. Specifies whether a read-only replica will be automatically promoted to read/write primary if the existing primary fails. If true, Multi-AZ is enabled for this replication group. If false, Multi-AZ is disabled for this replication group."
  default     = "false"
}

variable "azs" {
  description = "Which of the VPCs AZs, should be avaliable for the cluster, used by the subnet group"
  default     = ["eu-central-1a", "eu-central-1b"]
}

variable "auto_minor_version_upgrade" {
  description = "Redis only. Specifies whether a minor engine upgrades will be applied automatically to the underlying Cache Cluster instances during the maintenance window."
  default     = "true"
}

variable "redis_cluster_mode_num_node_groups" {
  description = "Redis cluster mode only. Specify the number of node groups (shards) for this Redis replication group. Changing this number will trigger an online resizing operation before other settings modifications."
  default     = ""
}

variable "redis_cluster_mode_replicas_per_node_group" {
  description = "Redis cluster mode only. Specify the number of replica nodes in each node group. Valid values are 0 to 5. Changing this number will force a new resource."
  default     = "0"
}
