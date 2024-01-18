variable "common" {
  type = object({
    project = string
    env = string
    region = string
    account_id = string
  })
}

variable "dns_cert_arn" {
  type = string
}

variable "network" {
  type = object({
    vpc_id = string
    subnet_ids = list(string)
  })
}