variable "common" {
  type = object({
    project = string
    env = string
    region = string
    account_id = string
  })
}

variable "image_tag_mutability" {
    type = string
}

variable "container_name" {
  type = string
}