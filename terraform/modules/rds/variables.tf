variable "environment" {
  description = "The environment (staging or production)"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the database"
  type        = list(string)
}

variable "db_instance_type" {
  description = "The instance type for the RDS database"
  type        = string
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

variable "cross_region_backup" {
  description = "Whether to enable cross-region backup replication"
  type        = bool
  default     = false
} 