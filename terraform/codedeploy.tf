resource "aws_codedeploy_app" "codedeploy_app" {
  compute_platform = "ECS"
  name             = local.name
}

resource "aws_codedeploy_deployment_config" "config_deploy" {
  deployment_config_name = local.name
  compute_platform       = "ECS"

  traffic_routing_config {
    type = "AllAtOnce"
  }
}

resource "aws_codedeploy_deployment_group" "codedeploy_deployment_group" {
  app_name               = aws_codedeploy_app.codedeploy_app.name
  deployment_group_name  = local.name
  service_role_arn       = aws_iam_role.codedeploy_role.arn
  deployment_config_name = aws_codedeploy_deployment_config.config_deploy.deployment_config_name

  ecs_service {
    cluster_name = aws_ecs_cluster.ecs_cluster.name
    service_name = aws_ecs_service.ecs_service.name
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout    = "CONTINUE_DEPLOYMENT"
      wait_time_in_minutes = 0
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_alb_listener.lb_listener_80.arn]
      }

      target_group {
        name = aws_alb_target_group.tg_blue.name
      }

      target_group {
        name = aws_alb_target_group.tg_green.name
      }

      test_traffic_route {
        listener_arns = [aws_alb_listener.lb_listener_8080.arn]
      }
    }
  }
}
