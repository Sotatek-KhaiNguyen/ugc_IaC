
########################################################
####  ECS role - task definitions - servivices #########
########################################################
resource "aws_security_group" "sg_service" {
  name        = "${var.common.env}-${var.common.project}-sg-${var.service_name}"
  description = "SG for ${var.service_name} group"
  vpc_id      = var.network.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "sg_rule_service" {
  type = "ingress"
  from_port = var.container_port
  to_port = var.container_port
  protocol = "TCP"
  source_security_group_id = var.sg_lb
  security_group_id = aws_security_group.sg_service.id
}

#########################################################

### ECS SERVICE ###
resource "aws_cloudwatch_log_group" "log_group" {
  name = "ecs/${var.common.env}-${var.common.project}-${var.service_name}"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "task_definition" {
  family = "${var.common.env}-${var.common.project}-${var.service_name}"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn = var.ecs.role_execution
  task_role_arn = var.ecs.role_ecs_service
  cpu = var.task_cpu
  memory = var.task_ram
  container_definitions = <<DEFINITION
    [
      {
        "name": "${var.container_name}",
        "image": "${var.common.account_id}.dkr.ecr.${var.common.region}.amazonaws.com/${var.common.env}-${var.common.project}-${var.container_name}:latest",
        "portMappings": [
          {
            "containerPort": ${var.container_port},
            "hostPort": ${var.container_port}
          }
        ],
        "logConfiguration": {
          "logDriver": "awslogs",
          "options": {
            "awslogs-region": "${var.common.region}",
            "awslogs-group": "ecs/${var.common.env}-${var.common.project}-${var.service_name}",
            "awslogs-stream-prefix": "ecs"
          }
        }
      }
    ]
  DEFINITION

  depends_on = [aws_cloudwatch_log_group.log_group]
}

resource "aws_ecs_service" "ecs_service" {
  name = "${var.common.env}-${var.common.project}-${var.service_name}"
  cluster = var.ecs.ecs_cluster_id
  task_definition = aws_ecs_task_definition.task_definition.arn
  lifecycle {
    ignore_changes = [task_definition]
  }
  launch_type = "FARGATE"
  platform_version = "1.4.0"
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent = 200
  desired_count = var.desired_count

  network_configuration {
    assign_public_ip = false
    subnets = var.network.subnet_ids
    security_groups = [aws_security_group.sg_service.id]
  }

  # load_balancer {
  #   target_group_arn = var.tg_arn
  #   container_port = var.container_port
  #   container_name = var.container_name
  # }

  dynamic "load_balancer" {
    for_each = var.use_load_balancer == true ? ["1"] : []
    content {
      target_group_arn = aws_lb_target_group.target_group[0].arn
      container_port   = var.container_port
      container_name   = var.container_name
    }
  }

  # depends_on = [aws_lb_listener_rule.lb_listener_rule]
}

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity = var.max_containers
  min_capacity = var.min_containers
  resource_id = "service/${var.ecs.ecs_cluster_name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace = "ecs"
  role_arn = var.ecs.role_auto_scaling
  lifecycle {
    ignore_changes = [role_arn]
  }
}

resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  name = "${var.common.env}-${var.common.project}-AutoScalingPolicyCPU-for-${var.service_name}"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown = "30"
    scale_out_cooldown = "30"
    target_value = var.auto_scaling_target_value_cpu
  }
}

resource "aws_appautoscaling_policy" "ecs_policy_ram" {
  name = "${var.common.env}-${var.common.project}-AutoScalingPolicyRAM-for-${var.service_name}"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    scale_in_cooldown = "30"
    scale_out_cooldown = "30"
    target_value = var.auto_scaling_target_value_ram
  }
}

###LOADBALANCER_TARGETGOUP###

resource "aws_lb_target_group" "target_group" {
  count       = var.use_load_balancer == true ? 1 : 0
  name        = "${var.common.env}-${var.common.project}-${var.container_name}"
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.network.vpc_id

  health_check {
    interval            = 60
    path                = var.healthcheck_path
    port                = var.container_port
    timeout             = 30
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}


resource "aws_lb_listener_rule" "lb_listener_rule" {
  count        = var.use_load_balancer == true ? 1 : 0
  listener_arn = var.aws_lb_listener_arn
  priority     = var.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group[0].arn
  }

  condition {
    host_header {
      values = [var.host_header]
    }
  }
}

#########S3 FOR DATA ###################
resource "aws_s3_bucket" "s3" {
  count       = var.use_s3_for_data == true ? 1 : 0
  bucket = "${var.common.env}-${var.common.project}-${var.container_name}-data"
}