variable "common" {
  type = object({
    project = string
    env = string
    region = string
    account_id = string
  })
}

variable "service_name" {
  type = string
}

variable "container_name" {
  type = string
}

variable "command" {
  type = string
}

variable "container_port" {
  type = number
}

variable "desired_count" {
  type = string
}

variable "task_cpu" {
  type = string
}

variable "task_ram" {
  type = string
}

variable "min_containers" {
  type = string
}

variable "max_containers" {
  type = string
}

variable "auto_scaling_target_value_cpu" {
  type = string
}

variable "auto_scaling_target_value_ram" {
  type = string
}

variable "sg_lb" {
  type = string
}

variable "priority" {
  type = string
}

variable "ecs" {
  type = object({
    role_auto_scaling = string
    role_execution = string
    role_ecs_service = string
    ecs_cluster_id = string
    ecs_cluster_name = string
  })
}

variable "network" {
  type = object({
    vpc_id = string
    subnet_ids = list(string)
    #sg_container = string
  })
}

variable "aws_lb_listener_arn" {}

variable "host_header" {
  type = string
}

variable "ecs_service" {}

variable "use_load_balancer" {}

variable "healthcheck_path" {}

variable "use_s3_for_data" {}