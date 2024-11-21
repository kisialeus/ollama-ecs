# Application Load Balancer
resource "aws_alb" "main" {
  name             = "${var.project_prefix}-${var.env}-alb"
  subnets          = aws_subnet.public[*].id
  security_groups  = [aws_security_group.lb.id]

  tags = {
    Name = "${var.project_prefix}-${var.env}-alb"
  }
}

# Target Group
resource "aws_alb_target_group" "app" {
  name        = "${var.project_prefix}-${var.env}-target-group"
  port        = var.app.port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.default.id
  target_type = "ip"

  health_check {
    healthy_threshold   = 3
    interval            = 30
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = 3
    path                = var.app.health_check_path
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_prefix}-${var.env}-target-group"
  }
}

# Listener
resource "aws_alb_listener" "front_end" {
  load_balancer_arn = aws_alb.main.arn
  port              = var.app.port
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.app.arn
    type             = "forward"
  }

  tags = {
    Name = "${var.project_prefix}-${var.env}-listener"
  }
}
