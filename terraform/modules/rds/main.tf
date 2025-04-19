resource "aws_security_group" "db" {
  name        = "ptchampion-${var.environment}-db-sg"
  description = "Security group for PT Champion database"
  vpc_id      = var.vpc_id

  # Allow incoming PostgreSQL traffic from private subnets only
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    cidr_blocks     = ["10.0.0.0/8"]
    description     = "Allow PostgreSQL access from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ptchampion-${var.environment}-db-sg"
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "ptchampion-${var.environment}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "ptchampion-${var.environment}-db-subnet-group"
  }
}

resource "aws_db_parameter_group" "postgres" {
  name   = "ptchampion-${var.environment}-postgres-params"
  family = "postgres14"
  
  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_statement"
    value = "ddl"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"  # Log queries taking more than 1 second
  }

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"  # For query performance analysis
  }
}

resource "aws_db_instance" "postgres" {
  identifier             = "ptchampion-${var.environment}-db"
  engine                 = "postgres"
  engine_version         = "14.10"
  instance_class         = var.db_instance_type
  allocated_storage      = 20
  max_allocated_storage  = 100  # Enables storage autoscaling up to 100GB
  storage_type           = "gp3"
  storage_encrypted      = true
  
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  
  vpc_security_group_ids = [aws_security_group.db.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  parameter_group_name   = aws_db_parameter_group.postgres.name
  
  backup_retention_period = 7  # Keep backups for 7 days
  backup_window           = "03:00-04:00"  # UTC time
  maintenance_window      = "mon:04:00-mon:05:00"
  
  auto_minor_version_upgrade = true
  deletion_protection        = true
  skip_final_snapshot        = false
  final_snapshot_identifier  = "ptchampion-${var.environment}-final-snapshot"
  
  performance_insights_enabled          = true
  performance_insights_retention_period = 7  # 7 days
  monitoring_interval                   = 60  # Enhanced monitoring every 60 seconds
  monitoring_role_arn                   = aws_iam_role.rds_monitoring_role.arn
  
  tags = {
    Name = "ptchampion-${var.environment}-db"
  }
}

# IAM role for enhanced monitoring
resource "aws_iam_role" "rds_monitoring_role" {
  name = "ptchampion-${var.environment}-rds-monitoring-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring_role_policy" {
  role       = aws_iam_role.rds_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# Enable automated backups to S3
resource "aws_db_instance_automated_backups_replication" "backup_replication" {
  count                  = var.cross_region_backup ? 1 : 0
  source_db_instance_arn = aws_db_instance.postgres.arn
  retention_period       = 7
} 