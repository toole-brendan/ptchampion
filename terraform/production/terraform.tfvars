# Resource Group and Location
resource_group_name = "ptchampion-rg"
location            = "eastus"

# Container Registry
acr_name = "ptchampionacr"

# Database
db_server_name     = "ptchampion-db"
db_name            = "ptchampion"
db_admin_username  = "ptadmin"
db_admin_password  = "PTChampion123!" # This should be the actual password

# Redis
redis_name = "ptchampion-redis"

# Key Vault
key_vault_name = "ptchampion-kv"

# App Service
app_service_plan_name = "ptchampion-plan-westus"
app_service_name      = "ptchampion-api-westus"

# Container Image
container_image     = "ptchampion"
container_image_tag = "latest"

# JWT Secret
jwt_secret = "f8a4c3ff94e950fa7b1245d3fe57562d148c371aab9233428c849e9d7ba6d251" 