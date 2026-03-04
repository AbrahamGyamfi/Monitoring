resource "aws_codedeploy_app" "taskflow" {
  name = "taskflow-app"
  
  tags = {
    Name = "taskflow-codedeploy-app"
  }
}

resource "aws_codedeploy_deployment_group" "taskflow" {
  app_name               = aws_codedeploy_app.taskflow.name
  deployment_group_name  = "taskflow-blue-green"
  service_role_arn       = aws_iam_role.codedeploy_role.arn
  deployment_config_name = "CodeDeployDefault.OneAtATime"
  
  deployment_style {
    deployment_type   = "BLUE_GREEN"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }
  
  load_balancer_info {
    target_group_info {
      name = var.target_group_name
    }
  }
  
  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
  
  ec2_tag_filter {
    key   = "Name"
    type  = "KEY_AND_VALUE"
    value = "taskflow-app"
  }
}

resource "aws_iam_role" "codedeploy_role" {
  name = "taskflow-codedeploy-role"
  
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
}

resource "aws_iam_role_policy" "codedeploy_service_policy" {
  name = "taskflow-codedeploy-service-policy"
  role = aws_iam_role.codedeploy_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "autoscaling:*",
          "elasticloadbalancing:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "codedeploy_ec2_policy" {
  name = "taskflow-codedeploy-ec2-policy"
  role = aws_iam_role.codedeploy_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "ec2_codedeploy_role" {
  name = "taskflow-ec2-codedeploy-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_codedeploy_policy" {
  role       = aws_iam_role.ec2_codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}

resource "aws_iam_role_policy" "ec2_s3_policy" {
  name = "taskflow-ec2-s3-policy"
  role = aws_iam_role.ec2_codedeploy_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy" "ec2_jenkins_policy" {
  name = "taskflow-ec2-jenkins-policy"
  role = aws_iam_role.ec2_codedeploy_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "arn:aws:ssm:*:*:parameter/taskflow/*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_codedeploy_profile" {
  name = "taskflow-ec2-codedeploy-profile"
  role = aws_iam_role.ec2_codedeploy_role.name
}

output "codedeploy_app_name" {
  value = aws_codedeploy_app.taskflow.name
}

output "codedeploy_deployment_group" {
  value = aws_codedeploy_deployment_group.taskflow.deployment_group_name
}

output "ec2_instance_profile_name" {
  value = aws_iam_instance_profile.ec2_codedeploy_profile.name
}
