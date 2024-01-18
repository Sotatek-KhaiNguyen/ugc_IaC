resource "aws_security_group" "sg_ecs_task" {
  name        = "${var.common.env}-${var.common.project}-ecs-task"
  description = "SG default for ECS Tasks"
  vpc_id      = var.network.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "role_auto_scaling" {
  name = "${var.common.env}-${var.common.project}-as"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns  = ["arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"]
}

resource "aws_iam_role" "role_execution" {
  name = "${var.common.env}-${var.common.project}-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns  = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]
}

resource "aws_iam_role" "role_ecs_service" {
  name = "${var.common.env}-${var.common.project}-ecs-service"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "policy_execution" {
  name = "${var.common.env}-${var.common.project}-execution"
  role = aws_iam_role.role_execution.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetIamge",
          "ecr:GetAuthorizationToken",
          "ecr:GetDownloadUrlForLayer",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.common.env}-${var.common.project}"
}

output "sg_ecs_task" {
  value = aws_security_group.sg_ecs_task.id
}

locals {
  role_auto_scaling_arn = aws_iam_role.role_auto_scaling.arn
  role_execution_arn = aws_iam_role.role_execution.arn
  role_ecs_service_arn = aws_iam_role.role_ecs_service.arn
  ecs_cluster_id = aws_ecs_cluster.ecs_cluster.id
  ecs_cluster_name = aws_ecs_cluster.ecs_cluster.name
}

output "role_auto_scaling" {
  value = aws_iam_role.role_auto_scaling.arn
}

output "role_execution" {
  value = aws_iam_role.role_execution.arn
}

output "role_ecs_service" {
  value = aws_iam_role.role_ecs_service.arn
}

output "ecs_cluster_id" {
  value = aws_ecs_cluster.ecs_cluster.id
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.ecs_cluster.name
}