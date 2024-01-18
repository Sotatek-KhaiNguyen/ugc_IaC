variable "common" {
  type = object({
    project = string
    env = string
    region = string
    account_id = string
  })
}

variable "network" {
  type = object({
    vpc_id = string
  })
}
