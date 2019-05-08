variable "region" {}
variable "stack" {}
variable "environment" {}
variable "brand" {}

variable "ecs_vpc_id" {}

variable "ecs_cluster_sg_id" {}

variable "ecs_name" {}

variable "ecs_tag" {
  default = "latest"
}

variable "app_name" {}

variable "branch" {
  default = "master"
}

variable "autoscaling_max_capacity" {
  default = 8
}

variable "autoscaling_min_capacity" {
  default = 2
}

variable "autoscaling_cpu_up_threshold" {
  description = "The CPU usage threshold, at which the cluster will scale up"
  default     = 75
}

variable "autoscaling_cpu_down_threshold" {
  description = "The CPU usage threshold, at which the cluster will scale down"
  default     = 50
}

variable "autoscaling_mem_up_threshold" {
  description = "The Memory usage threshold, at which the cluster will scale up"
  default     = 75
}

variable "autoscaling_mem_down_threshold" {
  description = "The Memory usage threshold, at which the cluster will scale down"
  default     = 50
}

variable "task_count" {
  default = "2"
}

variable "frontend_container_name" {
  description = "The name of the webserver running on the frontend container i.e \"nginx\""
  default     = "nginx"
}

variable "frontend_port_mappings" {
  description = "TASK DEFINITION - A list of maps, each map can contain up to three keys: \"container_port\" (mandatory), \"host_port\" and \"protocol\". When left unset the frontend container will map the frontend_container_port"
  type        = "list"
  default     = []
}

variable "frontend_container_port" {
  default = "443"
}

variable "ssm_lookup_app_name_override" {
  description = "Overrides the app name in the SSM lookup. Should only be used if multiple apps need to use the same elasticach/rds instance"
  default     = ""
}

variable "healthcheck_path" {
  description = "ALB healthcheck path"
  default     = "/"
}

variable "healthcheck_matcher" {
  description = "The HTTP codes to use when checking for a successful response from a target. You can specify multiple values (i.e, \"200,202\") or a range of values (i.e, \"200-299\")."
  default     = "200"
}

variable "lb_listener_ports" {
  default = ["443"]
  type    = "list"
}

variable "td_cpu" {
  description = "Task Definition CPU"
  default     = "512"
}

variable "task_role_arn" {
  description = "The role to attached to the task, giving the container access to AWS resources"
  default     = ""
}

variable "td_memory" {
  description = "Task Definition Memory"
  default     = "256"
}

variable "repository-urls" {
  description = "A list of the Ecr repositories that are used by the Task Definition to create the containers"
  type        = "list"
}

variable "essential" {
  default = true
}

variable "mount_points" {
  description = "A list of maps, part of the task definition. used to mount volumes on the container. check 'MountPoints' in aws task definition documentation"
  type        = "list"
  default     = []
}

variable "volumes_from" {
  description = "A list of maps, part of the task definition. used to mount volumes from a diffrent container. check 'volumesFrom' in aws task definition documentation"
  type        = "list"
  default     = []
}

variable "logging_driver" {
  description = "The logging driver to use with the task definition"
  default     = "awslogs"
}

variable "db_environment" {
  description = "A map of DB related environment variables, will be passed from the RDS pipeline."
  type        = "map"
  default     = {}
}

variable "frontend_environment" {
  description = "A map of environment variables that will be populated in the frontend container."
  type        = "map"
  default     = {}
}

variable "backend_environment" {
  description = "A map of environment variables that will be populated in all backend containers."
  type        = "map"
  default     = {}
}

variable "volume_definition" {
  description = "Part of the task definition TF resource, maps avaliable volumes from the ecs cluster to the containers, contains two keys 'volume_name' and 'host_path'"
  type        = "map"

  default = {
    volume_name = ""

    host_path = ""
  }
}

variable "ssm_rds_parameters" {
  description = "Should RDS parameters be looked up from SSM"
  default     = false
}

variable "route53_zone_name" {
  description = "Name of route53 zone an entry should be created in"
  default     = "elb.beamly.com"
}

variable "enable_logs" {
  description = "Set to false to disable the tf-logs module"
  default     = true
}

variable "enable_alb" {
  description = "Set to false to disable alb creation"
  default     = true
}

variable "health_check_grace_period_seconds" {
  description = "Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 7200"
  default     = "180"
}

variable "ssm_redis_frontend_parameters" {
  description = "Should Redis frontend parameters be looked up from SSM"
  default     = false
}

variable "ssm_redis_backend_parameters" {
  description = "Should Redis backend parameters be looked up from SSM"
  default     = false
}

variable "scheduled_task_schedule_expression" {
  description = "An expression to set the scheduled task sehedule, i.e cron(0 0 * * ? *) or rate(5 minutes)"
  default     = ""
}

variable "scheduled_task_command" {
  description = "The command that the scheduled task should run, specified as a list i.e ['ls', '-l']"
  type        = "list"
  default     = [""]
}

variable "scheduled_task_container" {
  description = "The container that should be used to run the scheduled task, should only be specified if there is more than one container in the tast definition"
  default     = ""
}

variable "extra_policy_actions" {
  description = "Extra IAM 'Allow' premissions that will be added to the ecs-service role. Actions (i.e s3:ListAllMyBuckets) if specified must be used with extra_policy_resources"
  type        = "list"
  default     = []
}

variable "extra_policy_resources" {
  description = "Extra IAM 'Allow' premissions that will be added to the ecs-service role. Resources (i.e arn:aws:s3:::*) if specified must be used with extra_policy_actions"
  type        = "list"
  default     = []
}

variable "entrypoint" {
  description = "When specified will add an entrypoint to the task definition"
  default     = []
  type        = "list"
}

variable "command" {
  description = "When specified will add command (docker run) to the task definition"
  default     = []
  type        = "list"
}

variable "internal_alb" {
  description = "When set to true the alb will routes requests from clients to targets using private IP addresses (will not be internet facing)"
  default     = "false"
}

variable "ssm_keys" {
  description = "A list of maps. Key should be env varname and value full path of ssm key [{envVarName = ssmKey}] that should be added to the task definition as env vars. If ssm_keys are specified a policy giving access to said keys should also be added (via extra_policy_actions and extra_policy_resources"
  type        = "list"
  default     = []
}
