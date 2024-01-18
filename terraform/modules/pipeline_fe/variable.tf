#variable "OAuthToken" {}
variable "gitRepo" {}
variable "gitBranch" {}
variable "codepipelineRoleArn" {}
variable "bucketName" {}

variable "common" {
  type = object({
    project = string
    env = string
    region = string
    account_id = string
  })
}


variable "codebuildRoleArn" {}
variable "codedeployRoleArn" {}
variable "codebuild_image" {}
variable "codebuild_compute_type" {}
variable "github_repos" {}
#variable "codebuild_buildspec" {}
variable "service" {}
variable "lambda_endpoint" {}
variable "lambda_secret" {}
variable "buildspec_file" {}
variable "buildspec_variables"{}