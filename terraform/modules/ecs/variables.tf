variable "environment" {
  description = "The environment (staging or production)"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the ECS tasks"
  type        = list(string)
}

variable "ecr_repository_url" {
  description = "The URL of the ECR repository"
  type        = string
}

variable "api_image_tag" {
  description = "The tag of the API Docker image to deploy"
  type        = string
}

variable "container_port" {
  description = "The port the container is listening on"
  type        = number
  default     = 8080
}

variable "container_cpu" {
  description = "The number of CPU units to allocate to the container"
  type        = number
  default     = 256
}

variable "container_memory" {
  description = "The amount of memory to allocate to the container"
  type        = number
  default     = 512
}

variable "service_desired_count" {
  description = "The desired number of tasks in the service"
  type        = number
  default     = 2
}

variable "service_min_count" {
  description = "The minimum number of tasks in the service"
  type        = number
  default     = 1
}

variable "service_max_count" {
  description = "The maximum number of tasks in the service"
  type        = number
  default     = 4
}

variable "domain_name" {
  description = "The domain name for the API"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "The ARN of the SSL certificate to use for HTTPS"
  type        = string
}

variable "db_host" {
  description = "The hostname of the RDS instance"
  type        = string
}

variable "db_port" {
  description = "The port of the RDS instance"
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "The name of the database"
  type        = string
}

variable "db_username" {
  description = "The username for the database"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "The password for the database"
  type        = string
  sensitive   = true
}

variable "redis_host" {
  description = "The hostname of the Redis instance"
  type        = string
}

variable "redis_port" {
  description = "The port of the Redis instance"
  type        = number
  default     = 6379
}

variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "account_id" {
  description = "The AWS account ID"
  type        = string
} 