variable "common" {
  type = object({
    project = string
    env = string
    region = string
    account_id = string
  })
}


####RDS##########
# variable "dev_postgresql_log" {}

# # ####REDIS#######
# variable "dev_redis_slowly_logs" {}
# variable "dev_redis_engine_logs" {}