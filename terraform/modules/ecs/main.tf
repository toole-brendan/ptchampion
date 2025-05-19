### ECS Cluster ###
resource "aws_ecs_cluster" "main" {
  name = "ptchampion-${var.environment}-cluster"
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  
  tags = {
    Name = "ptchampion-${var.environment}-cluster"
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name
  
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  
  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
}

### IAM Roles ###
# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ptchampion-${var.environment}-ecs-task-execution-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role - Permissions for the actual application
resource "aws_iam_role" "ecs_task_role" {
  name = "ptchampion-${var.environment}-ecs-task-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Allow task to access secrets manager
resource "aws_iam_policy" "secrets_access" {
  name        = "ptchampion-${var.environment}-secrets-access"
  description = "Allow ECS tasks to access Secrets Manager"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:secretsmanager:*:*:secret:ptchampion-${var.environment}*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_role_secrets_access" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

### Security Groups ###
resource "aws_security_group" "ecs_tasks" {
  name        = "ptchampion-${var.environment}-ecs-tasks-sg"
  description = "Security group for PT Champion ECS tasks"
  vpc_id      = var.vpc_id
  
  ingress {
    protocol         = "tcp"
    from_port        = var.container_port
    to_port          = var.container_port
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "Allow inbound traffic to container port"
  }
  
  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "Allow all outbound traffic"
  }
  
  tags = {
    Name = "ptchampion-${var.environment}-ecs-tasks-sg"
  }
}

### Load Balancer ###
resource "aws_security_group" "alb" {
  name        = "ptchampion-${var.environment}-alb-sg"
  description = "Security group for PT Champion ALB"
  vpc_id      = var.vpc_id
  
  ingress {
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "Allow HTTP"
  }
  
  ingress {
    protocol         = "tcp"
    from_port        = 443
    to_port          = 443
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "Allow HTTPS"
  }
  
  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "Allow all outbound traffic"
  }
  
  tags = {
    Name = "ptchampion-${var.environment}-alb-sg"
  }
}

resource "aws_lb" "main" {
  name               = "ptchampion-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids
  
  enable_deletion_protection = var.environment == "production" ? true : false
  
  tags = {
    Name = "ptchampion-${var.environment}-alb"
  }
}

resource "aws_lb_target_group" "api" {
  name        = "ptchampion-${var.environment}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  
  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
  
  tags = {
    Name = "ptchampion-${var.environment}-tg"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"
  
  default_action {
    type = "redirect"
    
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

### ECS Task Definition ###
resource "aws_ecs_task_definition" "api" {
  family                   = "ptchampion-${var.environment}-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  
  container_definitions = jsonencode([
    {
      name         = "api"
      image        = "${var.ecr_repository_url}:${var.api_image_tag}"
      essential    = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "PORT"
          value = tostring(var.container_port)
        },
        {
          name  = "APP_ENV"
          value = var.environment
        }
      ]
      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:ptchampion-${var.environment}/database-url"
        },
        {
          name      = "JWT_SECRET"
          valueFrom = "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:ptchampion-${var.environment}/jwt-secret"
        },
        {
          name      = "REFRESH_TOKEN_SECRET"
          valueFrom = "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:ptchampion-${var.environment}/refresh-token-secret"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/ptchampion-${var.environment}-api"
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
  
  tags = {
    Name = "ptchampion-${var.environment}-api"
  }
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/ptchampion-${var.environment}-api"
  retention_in_days = 30
  
  tags = {
    Name = "ptchampion-${var.environment}-ecs-logs"
  }
}

### ECS Service ###
resource "aws_ecs_service" "api" {
  name                               = "ptchampion-${var.environment}-api"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.api.arn
  desired_count                      = var.service_desired_count
  launch_type                        = "FARGATE"
  platform_version                   = "LATEST"
  health_check_grace_period_seconds  = 60
  
  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }
  
  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api"
    container_port   = var.container_port
  }
  
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  
  # Auto-scaling is handled by app autoscaling
  
  lifecycle {
    ignore_changes = [desired_count]
  }
  
  depends_on = [
    aws_lb_listener.https
  ]
  
  tags = {
    Name = "ptchampion-${var.environment}-api-service"
  }
}

### Auto Scaling ###
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.service_max_count
  min_capacity       = var.service_min_count
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.api.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  name               = "ptchampion-${var.environment}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace
  
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  name               = "ptchampion-${var.environment}-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace
  
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    
    target_value       = 80.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

### Route53 DNS Records ###
data "aws_route53_zone" "main" {
  count = var.domain_name != "" ? 1 : 0
  name  = join(".", slice(split(".", var.domain_name), 1, length(split(".", var.domain_name))))
}

resource "aws_route53_record" "api" {
  count   = var.domain_name != "" ? 1 : 0
  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = var.domain_name
  type    = "A"
  
  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
} 