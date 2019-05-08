variable "project_name" {
  description = "Name of the project the cluster falls under"
}

variable "asg_max_size" {
  description = "Max size of auto scaling group for the ec2 instances that forms the cluster"
}

variable "asg_min_size" {
  description = "Min size of auto scaling group for the ec2 instances that forms the cluster"
}

variable "create_efs" {
  description = "Create an efs volume that will be mounted on the ec2 instances at launch time"
  default     = false
}

variable "key_name" {
  description = "Name of the ssh key that can be used to access the ec2 instances that forms the ecs cluster"
}

variable "brand" {
  description = "Brand associated with this stack. Optional"
  default     = ""
}

variable "stack" {
  description = "The root of the repo from which GoCD will run the pipeline. Optional"
  default     = ""
}

variable "environment" {
  description = "Name of the infrastructure environment to deploy into. Eg, 'dev', 'stage', 'prod'"
}

variable "region" {
  description = "Used by the output to generate logging configs for GoCD"
}

variable "branch" {
  description = "Branch of project being deployed (default: 'master')"
  default     = "master"
}

variable "cluster_instance_sizes" {
  description = "The size of the ec2 instances that will form the underlying infrastructure for the ecs cluster"
  default     = "t2.micro"
}

variable "tier" {
  description = "The name of the tier to deploy the app's ECS hosts into"
  default     = "private"
}

variable "office_ip" {
  description = "Cidr description of the office IP"
  type        = "list"
}

variable "vpc_id" {
  description = "The ID of the VPC the ECS cluster is being deployed in"
}

variable "additional_sg" {
  description = "IDs of other SG that will need to allow traffic to the cluster, such as the VPN SG"
  type        = "list"
  default     = []
}

variable "number_of_additional_sg" {
  description = "The number of additional security groups, used as the value of count"
  default     = 1
}
