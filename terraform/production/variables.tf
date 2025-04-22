variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "ptchampion-rg"
}

variable "location" {
  description = "The Azure region to deploy to"
  type        = string
  default     = "eastus"
}

variable "app_service_location" {
  description = "The Azure region for App Service resources"
  type        = string
  default     = "westus"
}

# Container Registry
variable "acr_name" {
  description = "The name of the Azure Container Registry"
  type        = string
  default     = "ptchampionacr"
}

# Database
variable "db_server_name" {
  description = "The name of the PostgreSQL server"
  type        = string
  default     = "ptchampion-db"
}

variable "db_name" {
  description = "The name of the database"
  type        = string
  default     = "ptchampion"
}

variable "db_admin_username" {
  description = "The admin username for the database"
  type        = string
  default     = "ptadmin"
}

variable "db_admin_password" {
  description = "The admin password for the database"
  type        = string
  sensitive   = true
}

# Redis
variable "redis_name" {
  description = "The name of the Redis cache"
  type        = string
  default     = "ptchampion-redis"
}

# Key Vault
variable "key_vault_name" {
  description = "The name of the Key Vault"
  type        = string
  default     = "ptchampion-kv"
}

# App Service
variable "app_service_plan_name" {
  description = "The name of the App Service Plan"
  type        = string
  default     = "ptchampion-plan-westus"
}

variable "app_service_name" {
  description = "The name of the App Service"
  type        = string
  default     = "ptchampion-api-westus"
}

# Container
variable "container_image" {
  description = "The name of the container image (without repository and tag)"
  type        = string
  default     = "ptchampion"
}

variable "container_image_tag" {
  description = "The tag of the container image"
  type        = string
  default     = "latest"
}

# JWT Secret
variable "jwt_secret" {
  description = "The JWT secret"
  type        = string
  sensitive   = true
} 