# Azure Production Terraform Configuration

This directory contains Terraform configurations for deploying the PT Champion application to Azure.

## Prerequisites

1. [Terraform](https://www.terraform.io/downloads.html) installed (v1.0.0+)
2. [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed and authenticated
3. Azure subscription with appropriate permissions
4. Docker installed locally for building container images

## Setup

1. Log in to Azure:
   ```
   az login
   ```

2. Create a file named `terraform.tfvars` based on the example:
   ```
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Edit `terraform.tfvars` with your specific values:
   ```
   # Make sure to change passwords and secrets
   vim terraform.tfvars
   ```

## Working with Existing Resources

If you need to import existing resources into Terraform state:

1. Store your subscription ID and resource group name:
   ```bash
   SUBSCRIPTION_ID="your-subscription-id"
   RESOURCE_GROUP="ptchampion-rg"
   ```

2. Import resources one by one:
   ```bash
   terraform import -lock=false azurerm_container_registry.acr \
     /subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ContainerRegistry/registries/ptchampionacr
   
   terraform import -lock=false azurerm_redis_cache.redis \
     /subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Cache/redis/ptchampion-redis
   
   # Add more resources as needed
   ```

## Deployment Workflow

There are two main workflows:

### 1. Infrastructure Changes

To make changes to the infrastructure:

1. Update the Terraform files in this directory
2. Test your changes with:
   ```
   make azure-plan-production
   ```
3. Apply the changes:
   ```
   make azure-apply-production
   ```

### 2. Application Deployment

To deploy a new version of the application:

1. Build and deploy:
   ```
   make azure-deploy
   ```

   This command:
   - Builds the Go backend
   - Builds and tags a Docker image
   - Pushes the image to Azure Container Registry
   - Restarts the App Service to pull the latest image

2. View the logs:
   ```
   make azure-logs
   ```

## Make Commands Reference

```bash
# Initialize Terraform
make azure-init-production

# Plan Terraform changes
make azure-plan-production

# Apply Terraform changes
make azure-apply-production

# Build and push Docker image
make azure-build-push

# Deploy application (build, push image and restart App Service)
make azure-deploy

# View App Service logs
make azure-logs
```

## Troubleshooting

### Terraform State Lock Issues

If you encounter state lock errors:

```bash
az storage blob lease break --account-name ptchampionwebstorage \
  --container-name tfstate --blob-name terraform.tfstate
```

Then run your command with `-lock=false` flag:

```bash
terraform plan -lock=false
terraform apply -auto-approve -lock=false
```

### Importing Resources

If you get errors about resources already existing, you need to import them:

```bash
terraform import -lock=false [RESOURCE_TYPE].[RESOURCE_NAME] [RESOURCE_ID]
```

## Notes

- The `backend` configuration in `main.tf` uses Azure Storage for storing state
- Sensitive values like passwords are stored in Key Vault
- Location values are set to match current deployed resources
- App Service and App Service Plan are in West US region
- Other resources (Database, Redis, ACR) are in East US region 