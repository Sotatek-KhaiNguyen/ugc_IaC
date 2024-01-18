variable "common" {
  type = object({
    project = string
    env = string
    region = string
    account_id = string
  })
}

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