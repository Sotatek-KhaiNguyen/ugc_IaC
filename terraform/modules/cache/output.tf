
output "dev_redis_slowly_logs" {
  value = aws_cloudwatch_log_group.log_group_slowly.name
}

output "dev_redis_engine_logs" {
  value = aws_cloudwatch_log_group.log_group_engine.name
}