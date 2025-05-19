output "repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.repository.repository_url
}

output "repository_arn" {
  description = "The ARN of the ECR repository"
  value       = aws_ecr_repository.repository.arn
}

output "repository_registry_id" {
  description = "The registry ID of the ECR repository"
  value       = aws_ecr_repository.repository.registry_id
} 