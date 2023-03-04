resource "aws_ecs_cluster" "ecs_cluster" {
  name = local.name
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "task_definition" {
  family                   = local.name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_role.arn

  container_definitions = <<DEFINITION
[
  {
    "cpu": 256,
    "image": "${aws_ecr_repository.ecr_repo.repository_url}",
    "memory": 512,
    "name": "${local.name}",
    "networkMode": "awsvpc",
    "healthCheck": {
      "retries": 3,
      "command": [
          "CMD-SHELL",
          "curl -f http://localhost:80/index.html || exit 1"
      ],
      "timeout": 5,
      "interval": 5,
      "startPeriod": null
    },
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80,
        "protocol": "tcp"
      }
    ]
  }
]
DEFINITION
}

resource "aws_ecs_service" "ecs_service" {
  name             = local.name
  cluster          = aws_ecs_cluster.ecs_cluster.id
  task_definition  = aws_ecs_task_definition.task_definition.arn
  desired_count    = 2
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [aws_security_group.sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.tg_blue.arn
    container_name   = local.name
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [task_definition, load_balancer, desired_count]
  }
}

resource "aws_appautoscaling_target" "scaling_target" {
  max_capacity       = 20
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "scaling_up" {
  name               = "scale_up"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.scaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.scaling_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      metric_interval_upper_bound = 5000
      scaling_adjustment          = 2
    }

    step_adjustment {
      metric_interval_lower_bound = 5000
      scaling_adjustment          = 4
    }
  }
}

resource "aws_appautoscaling_policy" "scaling_down" {
  name               = "scale_down"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.scaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.scaling_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = -2000
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }

    step_adjustment {
      metric_interval_lower_bound = -5000
      metric_interval_upper_bound = -2000
      scaling_adjustment          = -2
    }

    step_adjustment {
      metric_interval_upper_bound = -5000
      scaling_adjustment          = -3
    }
  }
}
