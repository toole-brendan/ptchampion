terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "ptchampion-rg"
    storage_account_name = "ptchampionwebstorage"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }

  required_version = ">= 1.0.0"
}

provider "azurerm" {
  features {}

  # These can be set via environment variables:
  # ARM_SUBSCRIPTION_ID, ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID
}

# Use existing resource group
data "azurerm_resource_group" "ptchampion" {
  name = var.resource_group_name
}

# Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = data.azurerm_resource_group.ptchampion.name
  location            = data.azurerm_resource_group.ptchampion.location
  sku                 = "Standard"
  admin_enabled       = true
}

# Azure Database for PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "db" {
  name                   = var.db_server_name
  resource_group_name    = data.azurerm_resource_group.ptchampion.name
  location               = data.azurerm_resource_group.ptchampion.location
  version                = "13"
  administrator_login    = var.db_admin_username
  administrator_password = var.db_admin_password
  storage_mb             = 32768
  sku_name               = "B_Standard_B1ms"
  zone                   = "1"

  depends_on = [
    azurerm_key_vault_secret.db_password
  ]
}

# Azure Redis Cache
resource "azurerm_redis_cache" "redis" {
  name                = var.redis_name
  location            = data.azurerm_resource_group.ptchampion.location
  resource_group_name = data.azurerm_resource_group.ptchampion.name
  capacity            = 0
  family              = "C"
  sku_name            = "Basic"
  non_ssl_port_enabled = false
  minimum_tls_version = "1.2"
}

# Get current client configuration
data "azurerm_client_config" "current" {}

# Key Vault
resource "azurerm_key_vault" "kv" {
  name                       = var.key_vault_name
  location                   = data.azurerm_resource_group.ptchampion.location
  resource_group_name        = data.azurerm_resource_group.ptchampion.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days = 90
  purge_protection_enabled   = false
  sku_name                   = "standard"
  enable_rbac_authorization  = true
}

# Key Vault access policy for the current user/service principal
resource "azurerm_key_vault_access_policy" "deployer" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Purge"
  ]
}

# Store database password in Key Vault
resource "azurerm_key_vault_secret" "db_password" {
  name         = "DB-PASSWORD"
  value        = var.db_admin_password
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_key_vault_access_policy.deployer]
}

# App Service Plan
resource "azurerm_service_plan" "appplan" {
  name                = var.app_service_plan_name
  location            = var.app_service_location
  resource_group_name = data.azurerm_resource_group.ptchampion.name
  os_type             = "Linux"
  sku_name            = "P1v2"
}

# App Service (Web App for Containers)
resource "azurerm_linux_web_app" "api" {
  name                = var.app_service_name
  location            = var.app_service_location
  resource_group_name = data.azurerm_resource_group.ptchampion.name
  service_plan_id     = azurerm_service_plan.appplan.id
  https_only          = false
  client_affinity_enabled = false

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on        = true
    ftps_state       = "FtpsOnly"
    health_check_path = "/health"
    http2_enabled    = true

    application_stack {
      docker_image_name = "ptchampion-api:latest"
      docker_registry_url = "https://${azurerm_container_registry.acr.login_server}"
      docker_registry_username = azurerm_container_registry.acr.admin_username
      docker_registry_password = azurerm_container_registry.acr.admin_password
    }
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "AZURE_KEY_VAULT_URL"     = azurerm_key_vault.kv.vault_uri
    "DEPLOY_ENV"              = "production"
    "DB_HOST"                 = azurerm_postgresql_flexible_server.db.fqdn
    "DB_NAME"                 = var.db_name
    "DB_USER"                 = var.db_admin_username
    "DB_PORT"                 = "5432"
    "DB_SSL_MODE"             = "require"
    "REDIS_HOST"              = azurerm_redis_cache.redis.hostname
    "REDIS_PORT"              = azurerm_redis_cache.redis.port
    "REDIS_PASSWORD"          = azurerm_redis_cache.redis.primary_access_key
    "PORT"                    = "8080"
    "CLIENT_ORIGIN"           = "https://ptchampion.ai"
    "JWT_SECRET"              = var.jwt_secret
    "REFRESH_TOKEN_SECRET"    = var.jwt_secret
    "WEBSITES_PORT"           = "8080"
    "DOCKER_REGISTRY_SERVER_URL"      = "https://${azurerm_container_registry.acr.login_server}"
    "DOCKER_REGISTRY_SERVER_USERNAME" = azurerm_container_registry.acr.admin_username
    "DOCKER_REGISTRY_SERVER_PASSWORD" = azurerm_container_registry.acr.admin_password
  }

  # Identity block will be managed by Azure
  # We'll read the existing identity instead of trying to create it

  logs {
    http_logs {
      file_system {
        retention_in_mb   = 100
        retention_in_days = 3
      }
    }
  }
}

# Give the App Service access to Key Vault
resource "azurerm_key_vault_access_policy" "app" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = azurerm_linux_web_app.api.identity[0].tenant_id
  object_id    = azurerm_linux_web_app.api.identity[0].principal_id

  secret_permissions = [
    "Get", "List"
  ]

  depends_on = [azurerm_linux_web_app.api]
}

# Outputs
output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "app_service_url" {
  value = "https://${azurerm_linux_web_app.api.default_hostname}"
}

output "postgres_server_fqdn" {
  value     = azurerm_postgresql_flexible_server.db.fqdn
  sensitive = true
}

output "redis_hostname" {
  value     = azurerm_redis_cache.redis.hostname
  sensitive = true
} 