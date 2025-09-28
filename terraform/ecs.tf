# terraform/ecs.tf

# Creates an ECS (Elastic Container Service) cluster to manage our services and tasks.
resource "aws_ecs_cluster" "strapi_cluster" {
  name = "${local.project_name}-cluster"

  tags = local.tags
}

# --- This data source looks up the manually created IAM role ---
data "aws_iam_role" "ecs_execution" {
  name = "ec2_ecr_full_access_role"
}

# Defines the task, which is a blueprint for our application.
resource "aws_ecs_task_definition" "strapi_task" {
  family                   = "${local.project_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = data.aws_iam_role.ecs_execution.arn

  # Defines the container(s) that will run as part of the task.
  container_definitions = jsonencode([
    {
      name      = "${local.project_name}-container"
      image     = data.aws_ecr_repository.strapi_app.repository_url
      essential = true
      portMappings = [
        {
          containerPort = var.strapi_port
          hostPort      = var.strapi_port
        }
      ]
      # --- SECTION TO UPDATE ---
      # Add your four generated keys here.
      environment = [
        { name = "HOST", value = "0.0.0.0" },
        { name = "PORT", value = tostring(var.strapi_port) },
        # --- PASTE YOUR GENERATED KEYS BELOW ---
        { name = "APP_KEYS", value = "2lRiLB0pHcTZYRleHW67twK6/CIlWwjpFRlk05zN8Mo=" },
        { name = "API_TOKEN_SALT", value = "/cu4QH8+eaZDI0RLJ7KeMcUZPur/hNPY9pO54zPjL+o=" },
        { name = "ADMIN_JWT_SECRET", value = "0uPl/PaAV6xpIZlNovRGtfpJK7okRIVk2JZJX30kt9M" },
        { name = "TRANSFER_TOKEN_SALT", value = "bcmZ/02AxoyuV0/Hz0z95IyPLrr/KiOLx90viPsnHrg=" },
        # You will also need to configure database variables here for a true production setup
        # For example:
        # { name = "DATABASE_CLIENT", value = "postgres" },
        # { name = "DATABASE_HOST", value = "your-rds-instance.rds.amazonaws.com" },
        # { name = "DATABASE_PORT", value = "5432" },
        # { name = "DATABASE_NAME", value = "strapi_db" },
        # { name = "DATABASE_USERNAME", value = "strapi_user" },
        # { name = "DATABASE_PASSWORD", value = "your_db_password" },
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = "/ecs/${local.project_name}"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = local.tags
}

# Creates the service that runs and maintains a specified number of instances of the task definition.
resource "aws_ecs_service" "strapi_service" {
  name            = "${local.project_name}-service"
  cluster         = aws_ecs_cluster.strapi_cluster.id
  task_definition = aws_ecs_task_definition.strapi_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = data.aws_subnets.default.ids
    security_groups = [aws_security_group.ecs_service.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.strapi.arn
    container_name   = "${local.project_name}-container"
    container_port   = var.strapi_port
  }

  # This ensures that the service waits for the ALB to be ready before starting.
  depends_on = [aws_lb_listener.strapi_http]

  tags = local.tags
}

# Creates a CloudWatch log group to store container logs.
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name = "/ecs/${local.project_name}"

  tags = local.tags
}

