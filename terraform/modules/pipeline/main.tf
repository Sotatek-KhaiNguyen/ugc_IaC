resource "aws_codebuild_project" "codebuild" {
  name         = "${var.common.env}-${var.common.project}-${var.gitRepo}"
  service_role = var.codebuildRoleArn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = var.codebuild_image
    image           = var.codebuild_compute_type
    privileged_mode = true
    type            = "LINUX_CONTAINER"
    dynamic "environment_variable"{

      for_each = var.buildspec_variables
      content {
        name = environment_variable.value.key
        value = environment_variable.value.value
      }
    }
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = templatefile("${var.buildspec_file}",{})
  }
}

resource "aws_codepipeline" "codepipeline" {
  name     = "${var.common.env}-${var.common.project}-${var.gitRepo}"
  role_arn = var.codepipelineRoleArn

  artifact_store {
    location = var.bucketName
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["Source_Artifacts"]

      configuration = {
        S3Bucket   = var.bucketName
        S3ObjectKey = format("%s/%s/metadata.zip",var.gitRepo,var.gitBranch)
        PollForSourceChanges = false
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["Source_Artifacts"]
      output_artifacts = ["Build_Artifacts"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.codebuild.name
      }
    }
  }

  dynamic "stage" {
    for_each = length(var.service) > 0 ? ["1"] : []
    content {
      name = "Deploy"
      dynamic "action" {
        for_each = var.service
        content {
          name            = "Deploy-${action.value}"
          category        = "Deploy"
          owner           = "AWS"
          provider        = "ECS"
          input_artifacts = ["Build_Artifacts"]
          version         = "1"
          configuration = {
            DeploymentTimeout = "20"
            ClusterName       = "${var.common.env}-${var.common.project}"
            ServiceName       = "${var.common.env}-${var.common.project}-${action.value}"
            FileName          = "artifact.json"
          }
        }
      }
    }
  }
}

# # Wire the CodePipeline webhook into a GitHub repository.
# resource "github_repository_webhook" "bar" {
#   repository = var.gitRepo

#   configuration {
#     url          = var.lambda_endpoint
#     content_type = "json"
#     insecure_ssl = false
#     secret       = var.lambda_secret
#   }

#   events = ["push"]
# }

# resource "gitlab_project_hook" "this" {
#   project                 = var.gitRepo
#   url                     = var.lambda_endpoint
#   token                   = var.lambda_secret
#   enable_ssl_verification = true
#   push_events             = true
# }

resource "aws_cloudwatch_event_rule" "pipeline-event" {
  name        = "${var.common.env}${var.common.project}-${var.gitRepo}-pipeline-event"
  description = "Cloud watch event when zip is uploaded to s3"

  event_pattern = <<EOF
{
  "source": ["aws.s3"],
  "detail-type": ["AWS API Call via CloudTrail"],
  "detail": {
    "eventSource": ["s3.amazonaws.com"],
    "eventName": ["PutObject", "CompleteMultipartUpload", "CopyObject"],
    "requestParameters": {
      "bucketName": ["${var.bucketName}"],
      "key": ["${format("%s/%s/metadata.zip",var.gitRepo,var.gitBranch)}"]
    }
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "code-pipeline" {
  rule      = aws_cloudwatch_event_rule.pipeline-event.name
  target_id = "SendToCodePipeline"
  arn       = aws_codepipeline.codepipeline.arn
  role_arn  = aws_iam_role.pipeline_event_role.arn
}
data "aws_iam_policy_document" "event_bridge_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }

}

resource "aws_iam_role" "pipeline_event_role" {
  name               = "${var.common.env}-${var.common.project}-${var.gitRepo}-event-bridge-role"
  assume_role_policy = data.aws_iam_policy_document.event_bridge_role.json
}

data "aws_iam_policy_document" "pipeline_event_role_policy" {
  statement {
    sid       = ""
    actions   = ["codepipeline:StartPipelineExecution"]
    resources = ["${aws_codepipeline.codepipeline.arn}"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "pipeline_event_role_policy" {
  name   = "${var.common.env}-${var.common.project}-${var.gitRepo}-event-policy"
  policy = data.aws_iam_policy_document.pipeline_event_role_policy.json
}

resource "aws_iam_role_policy_attachment" "pipeline_event_role_attach_policy" {
  role       = aws_iam_role.pipeline_event_role.name
  policy_arn = aws_iam_policy.pipeline_event_role_policy.arn
}