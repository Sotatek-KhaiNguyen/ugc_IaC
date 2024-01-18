variable "project" {
  type = string
  description = "Project name"
}

variable "env" {
  type = string
  description = "Environment name"
}

variable "region" {
  type = string
}

variable "account_id" {
  type = string
}

#======================ALB=================================
variable "dns_cert_arn" {
  type = string
}

#=======================ECR=====================================
variable "image_tag_mutability" {
    type = string
}

#=======================EC2=====================================
variable "ssh_public_key" {
  type = string
}
#=======================redis cache=====================================

variable "redis_engine_version" {
  type = string
}

variable "num_cache_nodes" {
  type = string
}

variable "node_type" {
  type = string
}

variable "ports" {
  type = list(string)
}

#=======================rds=====================================
variable "rds_port" {
  type = string
}

variable "rds_family" {
    type = string
}

variable "rds_engine" {
    type = string
}

variable "rds_engine_version" {
    type = string
}

variable "rds_name" {
    type = string
}

variable "rds_class" {
    type = string
}

variable "rds_strorage" {
    type = string
}

#========================ssm======================
variable "source_services" {
  type = set(string)
}

#========================ACM=======================
variable "domain_name_lb" {}

#=======================cf-fe=========================
variable "domain_cf_fe" {
  type = string
}

variable "domain_cf_static" {
  type = string
}

variable "domain_cf_samplenode" {
  type = string
}

variable "cf_cert_arn" {
  type = string
}

#=======================ecs-scale=============================
variable "ecs_service" {}

#====================VPC==============================
variable "vpc_cidr" {
  type        = string
  description = "The IP range to use for the VPC"
}

variable "public_subnet_numbers" {
  type = map(number)
  description = "Map of AZ to a number that should be used for public subnets"
}
 
variable "private_subnet_numbers" {
  type = map(number)
  description = "Map of AZ to a number that should be used for private subnets"
}

#========================CICD===================================
variable "codebuild_image" {}
variable "codebuild_compute_type" {}
variable "github_repos" {}

variable "github_repos_fe" {}
