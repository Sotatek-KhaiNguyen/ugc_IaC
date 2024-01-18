# terraform {
#   required_version = ">= 0.12"

#   required_providers {
#     aws = {
#         source = "hashicorp/aws"
#         version = "5.31.0"
#     }
#   } 
# }

# // information for secret manager
# data "aws_secretsmanager_secret" "ugc_secret_dev" {
#   name = "ugc_secret_dev"
# }

# // get data of secret manager
# data "aws_secretsmanager_secret_version" "ugc_secret_version" {
#   secret_id = data.aws_secretsmanager_secret.ugc_secret_dev.id
# }

# provider "github" {
#   token = jsondecode(data.aws_secretsmanager_secret_version.ugc_secret_version.secret_string)["githubtoken"]
#   #owner = "sotatek-dev"
#   owner = "Sotatek-KhaiNguyen"
# }

locals {
  common = {
    project = "${var.project}"
    env = "${var.env}"
    region = "${var.region}"
    account_id = "${var.account_id}"
  }

}

#========================tfstate management========================================
terraform {
  backend "s3" {
    bucket         = "terraform-state-ugc-dev"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
  }
}

#=========================VPC===============================================

module "vpc" {
  source = "../modules/vpc"
  common = local.common
  vpc_cidr = var.vpc_cidr
  public_subnet_numbers = var.public_subnet_numbers
  private_subnet_numbers = var.private_subnet_numbers
}


#=========================ECR================================================
module "ecr" {
  for_each = { for service in var.ecs_service : service["service_name"] => service }
  source = "../modules/ecr"
  common = local.common
  image_tag_mutability = var.image_tag_mutability
  container_name = each.value.container_name
}

#==========================EC2===============================================
module "ec2" {
  source = "../modules/bastionhost"
  common = local.common
  ssh_public_key = var.ssh_public_key
  vpc_id = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnet_ids[0]
}

#==========================Redis===============================================
module "redis" {
  source = "../modules/cache"
  common = local.common
  #network = var.network
  redis_engine_version = var.redis_engine_version
  num_cache_nodes = var.num_cache_nodes
  node_type = var.node_type
  ports = var.ports
  network = {
    vpc_id = module.vpc.vpc_id
    subnet_ids = [module.vpc.private_subnet_ids[0]]
  }
}

#===========================RDS===============================================
module "rds" {
  source = "../modules/database"
  common = local.common
  rds_engine = var.rds_engine
  rds_engine_version = var.rds_engine_version
  rds_name = var.rds_name
  rds_class = var.rds_class
  rds_strorage = var.rds_strorage
  rds_port = var.rds_port
  rds_family = var.rds_family
  network = {
    vpc_id = module.vpc.vpc_id
    subnet_ids = module.vpc.private_subnet_ids
  }
}

#===========================EXPORT_LOGS===============================================
module "export_logs" {
  source = "../modules/export_logs"
  common = local.common
  # dev_postgresql_log    = module.rds.dev_postgresql_log
  # dev_redis_slowly_logs = module.redis.dev_redis_slowly_logs
  # dev_redis_engine_logs = module.redis.dev_redis_engine_logs
}

#=========================SSM===============================================
module "ssm" {
  source = "../modules/ssm"
  common = local.common
  source_services = var.source_services
}

#========================ACM===============================================
module "acm" {
  source = "../modules/acm"
  common = local.common
  domain_name_lb = var.domain_name_lb
}

#========================Cloudfont===============================================
module "cf_fe" {
  source = "../modules/cloudfont"
  common = local.common
  name_cf = "fe"
  domain_cf = var.domain_cf_fe
  cf_cert_arn = var.cf_cert_arn
}

module "static" {
  source = "../modules/cloudfont"
  common = local.common
  name_cf = "static"
  domain_cf = var.domain_cf_static
  cf_cert_arn = var.cf_cert_arn
}

module "samplenode" {
  source = "../modules/cloudfont"
  common = local.common
  name_cf = "samplenode"
  domain_cf = var.domain_cf_samplenode
  cf_cert_arn = var.cf_cert_arn
}

#=========================Loadbalancer==========================================
module "alb" {
  source = "../modules/loadbalancer/alb"
  common = local.common
  network = {
    vpc_id = module.vpc.vpc_id
    subnet_ids = module.vpc.public_subnet_ids
  }
  dns_cert_arn = var.dns_cert_arn
}

#=============================ECS===============================================
module "ecs_base" {
  source = "../modules/ecs/ecs-base"
  common = local.common
  network = {
    vpc_id = module.vpc.vpc_id
  }
}

module "ecs_scale" {
  for_each = { for service in var.ecs_service : service["service_name"] => service }
  source = "../modules/ecs/ecs-with-scale"
  ecs_service = var.ecs_service
  common = local.common
  service_name = each.value.service_name
  container_name = each.value.container_name
  command = each.value.command
  container_port = each.value.container_port
  desired_count = each.value.desired_count
  task_cpu = each.value.task_cpu
  task_ram = each.value.task_ram
  min_containers = each.value.min_containers
  max_containers = each.value.max_containers
  auto_scaling_target_value_cpu = each.value.auto_scaling_target_value_cpu
  auto_scaling_target_value_ram = each.value.auto_scaling_target_value_ram
  use_load_balancer =  each.value.use_load_balancer
  healthcheck_path = each.value.healthcheck_path
  aws_lb_listener_arn = module.alb.aws_lb_listener_arn
  host_header = try(each.value.host_header, null)
  sg_lb = try(module.alb.sg_lb, null)
  priority = try(each.value.priority, null)
  use_s3_for_data = each.value.use_s3_for_data
  ecs = {
    role_auto_scaling = module.ecs_base.role_auto_scaling
    role_execution = module.ecs_base.role_execution
    role_ecs_service = module.ecs_base.role_ecs_service
    ecs_cluster_id = module.ecs_base.ecs_cluster_id
    ecs_cluster_name = module.ecs_base.ecs_cluster_name
  }
  network = {
    vpc_id = module.vpc.vpc_id
    subnet_ids = [module.vpc.private_subnet_ids[0]]
  }
}


#=========================CI/CD===============================================
module "pipelinebase" {
  source = "../modules/pipelinebase"
  common = local.common
}
module "codepipeline" {
  source = "../modules/pipeline"
  for_each = { for github in var.github_repos : github["name"] => github }
  common = local.common
  github_repos           = var.github_repos
  codebuild_image        = var.codebuild_image
  codebuild_compute_type = var.codebuild_compute_type
  bucketName             = module.pipelinebase.s3_bucket
  codepipelineRoleArn    = module.pipelinebase.codepipeline_role_arn
  gitBranch              = each.value.branch
  gitRepo                = each.value.name
  service                = each.value.service
  buildspec_variables    = each.value.buildspec_variables
  codebuildRoleArn       = module.pipelinebase.codebuild_role_arn
  codedeployRoleArn      = module.pipelinebase.codedeploy_role_arn
  lambda_endpoint        = module.pipelinebase.lambda_endpoint
  lambda_secret          = module.pipelinebase.secret_key
  buildspec_file         = "./buildspec/${each.value.name}.tftpl"
}

module "codepipeline_fe" {
  source = "../modules/pipeline_fe"
  for_each = { for github in var.github_repos_fe : github["name"] => github }
  common = local.common
  github_repos           = var.github_repos
  codebuild_image        = var.codebuild_image
  codebuild_compute_type = var.codebuild_compute_type
  bucketName             = module.pipelinebase.s3_bucket
  codepipelineRoleArn    = module.pipelinebase.codepipeline_role_arn
  gitBranch              = each.value.branch
  gitRepo                = each.value.name
  service                = each.value.service
  buildspec_variables    = each.value.buildspec_variables
  codebuildRoleArn       = module.pipelinebase.codebuild_role_arn
  codedeployRoleArn      = module.pipelinebase.codedeploy_role_arn
  lambda_endpoint        = module.pipelinebase.lambda_endpoint
  lambda_secret          = module.pipelinebase.secret_key
  buildspec_file         = "./buildspec_fe/${each.value.name}.tftpl"
}