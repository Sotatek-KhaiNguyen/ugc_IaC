variable "common" {
  type = object({
    project = string
    env = string
    region = string
    account_id = string
  })
}

variable "ssh_public_key" {
    type = string
}

# variable "network" {
#   type = object({
#     vpc_id = string
#     subnet_id = string
#     security_group = string
#   })
# }

# variable "iam_credentials" {
#   type = object({
#     key = string
#     secret = string
#   })
# }

variable "subnet_id" {
  type = string
}

variable "vpc_id" {
  type = string
}