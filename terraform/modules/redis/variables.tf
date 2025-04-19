variable "environment" {
  description = "The environment (staging or production)"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the Redis cache"
  type        = list(string)
}

variable "redis_instance_type" {
  description = "The instance type for the Redis cache"
  type        = string
} 