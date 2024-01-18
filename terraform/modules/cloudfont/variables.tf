variable "common" {
  type = object({
    project = string
    env = string
    region = string
    account_id = string
  }
  )
}

variable "domain_cf" {
  type = string
}

variable "name_cf" {
  type = string
}

variable "cf_cert_arn" {
  type = string
}
