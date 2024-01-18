output "codepipeline_arn" {
  value = aws_codepipeline.codepipeline.arn
}
output "object_endpoint" {
  value = format("%s/%s/metadata.zip",var.gitRepo,var.gitBranch)
}