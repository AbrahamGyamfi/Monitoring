resource "aws_lb" "taskflow" {
  name               = "taskflow-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.subnet_ids

  tags = {
    Name = "taskflow-alb"
  }
}

resource "aws_lb_target_group" "taskflow" {
  name        = "taskflow-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }

  tags = {
    Name = "taskflow-tg"
  }
}

resource "aws_lb_listener" "taskflow" {
  load_balancer_arn = aws_lb.taskflow.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.taskflow.arn
  }
}

resource "aws_lb_target_group_attachment" "blue" {
  target_group_arn = aws_lb_target_group.taskflow.arn
  target_id        = var.app_blue_instance_id
  port             = 80
}

resource "aws_lb_target_group_attachment" "green" {
  target_group_arn = aws_lb_target_group.taskflow.arn
  target_id        = var.app_green_instance_id
  port             = 80
}

output "load_balancer_dns" {
  value = aws_lb.taskflow.dns_name
}

output "target_group_arn" {
  value = aws_lb_target_group.taskflow.arn
}
