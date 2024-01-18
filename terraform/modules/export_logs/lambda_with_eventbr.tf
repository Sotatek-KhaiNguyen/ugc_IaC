resource "aws_iam_role" "lambda_role" {
  name = "${var.common.env}-${var.common.project}-export-logs"
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
  # inline_policy {
  #   name = "${var.common.env}-${var.common.project}-policy-export-logs"

  #   policy = jsonencode({
  #     Version = "2012-10-17"
  #     Statement = [
  #       {
  #         Action = [
  #           "cloudwatch:*",
  #           "logs:*"
  #         ]
  #         Effect   = "Allow"
  #         Resource = "*"
  #       },
  #       {
  #         Action = [
  #           "events:*",
  #           "scheduler:*"
  #         ]
  #         Effect   = "Allow"
  #         Resource = "*"
  #       },
  #       {
  #         Action = [
  #           "s3:*",
  #           "s3-object-lambda:*"
  #         ]
  #         Effect   = "Allow"
  #         Resource = "*"
  #       }
  #     ]
  #   })
  # }
}

resource "aws_iam_role_policy_attachment" "lambda_export_logs" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonS3FullAccess", 
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
    "arn:aws:iam::aws:policy/CloudWatchEventsFullAccess"
  ])
  role       = aws_iam_role.lambda_role.name
  policy_arn = each.value
}  

resource "random_string" "r" {
  length  = 5
  special = false
}

data "archive_file" "zipit" {
  type        = "zip"
  source_file = "../modules/export_logs/lambda_export.py"
  output_path = "${var.common.env}-${var.common.project}-lambda-export-log-${random_string.r.result}.zip"
}


resource "aws_lambda_function" "lambda" {
  function_name = "${var.common.env}-${var.common.project}-export-logs"
  filename = data.archive_file.zipit.output_path
  handler = "lambda_export.lambda_handler"
  role = aws_iam_role.lambda_role.arn
  publish = "false"
  runtime = "python3.10"
  source_code_hash = filebase64sha256("${data.archive_file.zipit.output_path}")
  timeout = "30"
  environment {
    variables = {
        #RDS_LOGS
        # dev_postgresql_log = var.dev_postgresql_log
        # #REDIS_LOGS
        # dev_redis_slowly_logs = var.dev_redis_slowly_logs
        # dev_redis_engine_logs = var.dev_redis_engine_logs
        # #ACHIVED_LOGS
        dev_s3_achived_logs = aws_s3_bucket.s3.bucket
    }
  }
}

resource "aws_lambda_function_url" "export_logs" {
  function_name      = aws_lambda_function.lambda.function_name
  authorization_type = "NONE"
}

#########S3 FOR ARCHIVED LOG ###################
resource "aws_s3_bucket" "s3" {
  bucket = "${var.common.env}-${var.common.project}-logs"
}

resource "aws_s3_bucket_policy" "allow_access_resource" {
  bucket = aws_s3_bucket.s3.id
  policy = data.aws_iam_policy_document.allow_access_resource.json
}

data "aws_iam_policy_document" "allow_access_resource" {
  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["arn:aws:s3:::${var.common.env}-${var.common.project}-logs"]
    actions   = ["s3:GetBucketAcl"]

    principals {
      type        = "Service"
      identifiers = ["logs.us-east-1.amazonaws.com"]
    }
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["arn:aws:s3:::${var.common.env}-${var.common.project}-logs/*"]
    actions   = ["s3:PutObject"]

    principals {
      type        = "Service"
      identifiers = ["logs.us-east-1.amazonaws.com"]
    }
  }
}
############### EVENT_BRIDGE ###################
resource "aws_cloudwatch_event_rule" "event" {
  name        = "dev-ugc-export-logs"
  schedule_expression = "rate(2 minutes)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.event.name
  target_id = "SendToLambda"
  arn       = aws_lambda_function.lambda.arn
  #role_arn  = aws_iam_role.lambda_event_role.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_event" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.lambda.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.event.arn
}