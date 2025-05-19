output "db_host" {
  description = "The hostname of the RDS instance"
  value       = aws_db_instance.postgres.address
  sensitive   = true
}

output "db_port" {
  description = "The port of the RDS instance"
  value       = aws_db_instance.postgres.port
}

output "db_name" {
  description = "The name of the database"
  value       = aws_db_instance.postgres.db_name
}

output "db_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.postgres.arn
}

output "db_sg_id" {
  description = "The ID of the database security group"
  value       = aws_security_group.db.id
} 