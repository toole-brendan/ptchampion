variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "The availability zones to use for subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "db_instance_type" {
  description = "The instance type for the RDS database"
  type        = string
  default     = "db.t3.small"
}

variable "db_name" {
  description = "The name of the database"
  type        = string
  default     = "ptchampion"
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

variable "redis_instance_type" {
  description = "The instance type for the Redis cache"
  type        = string
  default     = "cache.t3.small"
}

variable "ecr_repository_name" {
  description = "The name of the ECR repository"
  type        = string
  default     = "ptchampion-api"
}

variable "api_image_tag" {
  description = "The tag of the API Docker image to deploy"
  type        = string
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

variable "certificate_arn" {
  description = "The ARN of the SSL certificate to use for HTTPS"
  type        = string
} 