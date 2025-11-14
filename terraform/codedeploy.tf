# CodeDeploy Application
resource "aws_codedeploy_app" "ecs" {
  name             = "${var.project_name}-${var.environment}-codedeploy-app"
  compute_platform = "ECS"

  tags = {
    Name = "${var.project_name}-${var.environment}-codedeploy-app"
  }
}

# IAM Role for CodeDeploy
resource "aws_iam_role" "codedeploy" {
  name = "${var.project_name}-${var.environment}-codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "codedeploy.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-codedeploy-role"
  }
}

# Attach AWSCodeDeployRoleForECS policy
resource "aws_iam_role_policy_attachment" "codedeploy" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

# Additional policy for CodeDeploy to pass role to ECS
resource "aws_iam_role_policy" "codedeploy_pass_role" {
  name = "${var.project_name}-${var.environment}-codedeploy-pass-role"
  role = aws_iam_role.codedeploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "iam:PassRole"
      ]
      Resource = [
        aws_iam_role.ecs_task_execution_role.arn,
        aws_iam_role.ecs_task_role.arn
      ]
    }]
  })
}

# SNS Topic for CodeDeploy notifications
resource "aws_sns_topic" "codedeploy_notifications" {
  name = "${var.project_name}-${var.environment}-codedeploy-notifications"

  tags = {
    Name = "${var.project_name}-${var.environment}-codedeploy-notifications"
  }
}

# CodeDeploy Deployment Group
resource "aws_codedeploy_deployment_group" "ecs" {
  app_name               = aws_codedeploy_app.ecs.name
  deployment_group_name  = "${var.project_name}-${var.environment}-deployment-group"
  service_role_arn       = aws_iam_role.codedeploy.arn
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
      wait_time_in_minutes = 0
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.main.name
    service_name = aws_ecs_service.app.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.http.arn]
      }

      test_traffic_route {
        listener_arns = [aws_lb_listener.test.arn]
      }

      target_group {
        name = aws_lb_target_group.blue.name
      }

      target_group {
        name = aws_lb_target_group.green.name
      }
    }
  }

  # Uncomment to enable CloudWatch alarms for automatic rollback
  # alarm_configuration {
  #   alarms  = [aws_cloudwatch_metric_alarm.cpu_high.alarm_name]
  #   enabled = true
  # }

  trigger_configuration {
    trigger_events = [
      "DeploymentStart",
      "DeploymentSuccess",
      "DeploymentFailure",
      "DeploymentStop",
      "DeploymentRollback"
    ]
    trigger_name       = "${var.project_name}-${var.environment}-trigger"
    trigger_target_arn = aws_sns_topic.codedeploy_notifications.arn
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-deployment-group"
  }
}

# CloudWatch Alarms for monitoring (optional - uncomment to use)
# resource "aws_cloudwatch_metric_alarm" "cpu_high" {
#   alarm_name          = "${var.project_name}-${var.environment}-cpu-high"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "2"
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/ECS"
#   period              = "60"
#   statistic           = "Average"
#   threshold           = "85"
#   alarm_description   = "This metric monitors ECS CPU utilization"
#   alarm_actions       = [aws_sns_topic.codedeploy_notifications.arn]
#
#   dimensions = {
#     ClusterName = aws_ecs_cluster.main.name
#     ServiceName = aws_ecs_service.app.name
#   }
# }
