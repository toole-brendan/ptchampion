resource "aws_security_group" "redis" {
  name        = "ptchampion-${var.environment}-redis-sg"
  description = "Security group for PT Champion Redis cache"
  vpc_id      = var.vpc_id

  # Allow incoming Redis traffic from within the VPC
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    cidr_blocks     = ["10.0.0.0/8"]
    description     = "Allow Redis access from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ptchampion-${var.environment}-redis-sg"
  }
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "ptchampion-${var.environment}-redis-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "ptchampion-${var.environment}-redis-subnet-group"
  }
}

resource "aws_elasticache_parameter_group" "redis" {
  name   = "ptchampion-${var.environment}-redis-params"
  family = "redis6.x"
  
  # Default parameters are generally fine for most use cases
  # Add custom parameters as needed
  parameter {
    name  = "maxmemory-policy"
    value = "volatile-lru"  # Evict keys with expiration set using LRU
  }
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "ptchampion-${var.environment}-redis"
  description                = "PT Champion Redis cache for ${var.environment}"
  node_type                  = var.redis_instance_type
  port                       = 6379
  parameter_group_name       = aws_elasticache_parameter_group.redis.name
  security_group_ids         = [aws_security_group.redis.id]
  subnet_group_name          = aws_elasticache_subnet_group.redis.name
  
  # For production, use multiple nodes with automatic failover
  automatic_failover_enabled = var.environment == "production" ? true : false
  num_cache_clusters         = var.environment == "production" ? 2 : 1
  
  # Add replication group settings
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  
  # Auto-enable Multi-AZ if automatic failover is enabled
  multi_az_enabled           = var.environment == "production" ? true : false
  
  # Maintenance window (UTC)
  maintenance_window         = "sun:05:00-sun:06:00"
  
  # Snapshot settings
  snapshot_retention_limit   = var.environment == "production" ? 7 : 1  # Number of days to retain snapshots
  snapshot_window            = "03:00-04:00"  # Time (UTC) when snapshots are taken
  
  # Enable auto-minor version upgrades
  auto_minor_version_upgrade = true
  
  tags = {
    Name = "ptchampion-${var.environment}-redis"
  }
  
  lifecycle {
    prevent_destroy = true
  }
} 