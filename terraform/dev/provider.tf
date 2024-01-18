terraform {
  required_version = ">= 0.12"

  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "5.31.0"
    }
  } 
}

// information for secret manager
data "aws_secretsmanager_secret" "ugc_secret_dev" {
  name = "ugc_secret_dev"
}

// get data of secret manager
data "aws_secretsmanager_secret_version" "ugc_secret_version" {
  secret_id = data.aws_secretsmanager_secret.ugc_secret_dev.id
}

# provider "github" {
#   token = jsondecode(data.aws_secretsmanager_secret_version.ugc_secret_version.secret_string)["githubtoken"]
#   #owner = "sotatek-dev"
#   owner = "Sotatek-KhaiNguyen"
# }