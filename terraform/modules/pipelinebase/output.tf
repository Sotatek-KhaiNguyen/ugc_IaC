output "s3_bucket" {
  value = aws_s3_bucket.bucket_artifact.bucket
}
output "codebuild_role_arn" {
  value = aws_iam_role.codebuild_role.arn
}
output "codepipeline_role_arn" {
  value = aws_iam_role.pipeline_role.arn
}
output "codedeploy_role_arn" {
  value = aws_iam_role.codedeploy_role.arn
}
output "lambda_endpoint" {
  value = aws_lambda_function_url.test_latest.function_url
}
output "secret_key"{
  value = random_string.secret.result
}