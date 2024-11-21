# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_prefix}-${var.env}-ecs-cluster"
}

# ECS Task Definition Template
data "template_file" "cb_app" {
  template = file("./templates/ollama-template.tpl")

  vars = {
    app_image      = var.app.image
    app_port       = var.app.port
    fargate_cpu    = var.fargate.cpu
    fargate_memory = var.fargate.memory
    aws_region     = var.aws_region
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_prefix}-${var.env}-ecs-task"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate.cpu
  memory                   = var.fargate.memory
  container_definitions    = data.template_file.cb_app.rendered

  tags = {
    Name = "${var.project_prefix}-${var.env}-ecs-task"
  }
}

# ECS Service
resource "aws_ecs_service" "main" {
  name            = "${var.project_prefix}-${var.env}-ecs-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.app.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private[*].id
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.app.id
    container_name   = var.app.name
    container_port   = var.app.port
  }

  depends_on = [
    aws_alb_listener.front_end,
    aws_iam_role_policy_attachment.ecs-task-execution-role-policy-attachment
  ]

  tags = {
    Name = "${var.project_prefix}-${var.env}-ecs-service"
  }
}
