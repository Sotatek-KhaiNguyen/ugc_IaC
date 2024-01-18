resource "aws_iam_role" "lambda_role" {
  name = "${var.common.project}-${var.common.env}-webhook-endpoint"
  assume_role_policy = jsonencode({
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  inline_policy {
    name = "${var.common.project}-${var.common.env}-executionrole"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [

            "cloudwatch:*",
            "logs:*"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = [
            "s3:*"
          ]
          Effect   = "Allow"
          Resource = ["${aws_s3_bucket.bucket_artifact.arn}", "${aws_s3_bucket.bucket_artifact.arn}/*"]
        }
      ]
    })
  }
}
data "archive_file" "zipit" {
  type        = "zip"
  source_file = "../modules/pipelinebase/lambda.py"
  output_path = "${var.common.project}-${var.common.env}-lambda-${random_string.r.result}.zip"
}
resource "random_string" "r" {
  length  = 5
  special = false
}
resource "random_string" "secret" {
  length  = 16
  special = false
}
resource "aws_lambda_function" "lambda" {

  function_name = "${var.common.project}-${var.common.env}-webhook-endpoint"
  filename = data.archive_file.zipit.output_path
  handler = "lambda.lambda_handler"
  role = aws_iam_role.lambda_role.arn
  publish = "false"
  runtime = "python3.10"
  source_code_hash = filebase64sha256("${data.archive_file.zipit.output_path}")
  timeout = "30"
  environment {
    variables = {
      BUCKET = aws_s3_bucket.bucket_artifact.id
      SECRET_KEY = random_string.secret.result
    }
  }
}
resource "aws_lambda_function_url" "test_latest" {
  function_name      = aws_lambda_function.lambda.function_name
  authorization_type = "NONE"
}