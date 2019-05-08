tf-elasticache
Inputs
Name	Description	Type	Default	Required
app_name		string	-	yes
apply_immediately	If set to 'true' changes to the cluster will be applied immidiatly, otherwise, they will be applied during the next maintenane window	string	false	no
auto_minor_version_upgrade	Redis only. Specifies whether a minor engine upgrades will be applied automatically to the underlying Cache Cluster instances during the maintenance window.	string	true	no
automatic_failover	Redis only. Specifies whether a read-only replica will be automatically promoted to read/write primary if the existing primary fails. If true, Multi-AZ is enabled for this replication group. If false, Multi-AZ is disabled for this replication group.	string	false	no
azs	Which of the VPCs AZs, should be avaliable for the cluster, used by the subnet group	string	<list>	no
brand		string	-	yes
ecs_cluster_sg_id	ID of ecs-cluster sg. Only needed to allow module chaning via GoCD	string	``	no
engine	Elasticache engine, should be 'redis' or 'memcached'	string	-	yes
engine_version	Elasticache engine version, defaults to '1.5.10' for memcached and '5.0.0' for redis	string	``	no
environment		string	-	yes
inbound_security_groups	IDs of other SG that will need to allow traffic to the cluster, i.e ecs	list	<list>	no
maintenance_window	Specifies the weekly time range for when maintenance on the cache cluster is performed. The format is ddd:hh24:mi-ddd:hh24:mi (24H Clock UTC). The minimum maintenance window is a 60 minute period. Example: sun:05:00-sun:09:00	string	``	no
node_type	Elasticache node type, that should be used for the cluster	string	cache.t2.micro	no
num_cache_nodes	Not used for redis-cluster mode. Number of cache nodes (primary + replica for redis), accepted values: memcache 1-20, redis 1-5	string	1	no
parameter_group_name	Elasticache parameter group to use for the cluster, defaults to 'default.redis5.0' for redis and 'default.memcached1.5' for memcache	string	``	no
port	Port nunber for the cluster, defaults to '11211' for memcached and '6379' for redis	string	``	no
preferred_availability_zones	A list of the Availability Zones in which cache nodes are created. The number of Availability Zones listed must equal the value of num_cache_nodes	list	<list>	no
redis_cluster_mode_num_node_groups	Redis cluster mode only. Specify the number of node groups (shards) for this Redis replication group. Changing this number will trigger an online resizing operation before other settings modifications.	string	``	no
redis_cluster_mode_replicas_per_node_group	Redis cluster mode only. Specify the number of replica nodes in each node group. Valid values are 0 to 5. Changing this number will force a new resource.	string	0	no
snapshot_retention_limit	Redis only. The number of days for which ElastiCache will retain automatic cache cluster snapshots before deleting them. If the value of SnapshotRetentionLimit is set to zero (0), backups are turned off	string	0	no
snapshot_window	Redis only. The daily time range (in UTC) during which ElastiCache will begin taking a daily snapshot of your cache cluster. Example: 05:00-09:00	string	``	no
stack		string	-	yes
total_number_of_inbound_security_groups	The total number security groups (inbound + ecs_cluster vars), used as the value of count	string	0	no
vpc_id	The vpc ID for the VPC in which the elasticache cluster will be created	string	-	yes
Outputs
Name	Description
elasticache_endpoint	
elasticache_id	
elasticache_sg_id	
elasticache_subnet_group_name
