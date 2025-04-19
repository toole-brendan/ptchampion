# Azure Deployment Guide

This document outlines the steps to deploy the PT Champion application to Microsoft Azure.

## Architecture Overview

The PT Champion application is deployed to Azure using the following services:

- **Azure App Service for Containers**: Hosts the Go backend API
- **Azure Database for PostgreSQL - Flexible Server**: Managed PostgreSQL database
- **Azure Cache for Redis**: Used for leaderboard caching and session management
- **Azure Storage Account**: Static website hosting for the React web frontend
- **Azure Front Door**: Global CDN, WAF protection, and custom domain mapping
- **Azure Container Registry**: Stores and manages Docker images
- **Azure Monitor & Application Insights**: For logging, monitoring, and alerting
- **Azure Key Vault**: Secures application secrets and certificates

## Prerequisites

1. **Azure Account**: Active Azure subscription
2. **Azure CLI**: [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
3. **Terraform**: [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) (if using infrastructure as code)
4. **GitHub Repository**: Access to the PT Champion repository with GitHub Actions enabled

## Setting Up Azure Resources

### Option 1: Using Terraform (Recommended)

1. **Initialize Azure Authentication**

   ```bash
   az login
   az account set --subscription "Your Subscription Name or ID"
   ```

2. **Create Service Principal for CI/CD**

   ```bash
   # Create a service principal with Contributor role
   az ad sp create-for-rbac --name "ptchampion-github" --role Contributor \
     --scopes /subscriptions/YOUR_SUBSCRIPTION_ID \
     --json-auth
   ```

   Save the output JSON - you'll need these values for GitHub secrets.

3. **Deploy Infrastructure with Terraform**

   ```bash
   cd terraform/staging  # or terraform/production
   terraform init
   terraform plan
   terraform apply
   ```

   This will create all necessary Azure resources defined in the Terraform modules.

### Option 2: Manual Resource Creation

1. **Create Resource Group**

   ```bash
   az group create --name ptchampion-rg --location eastus
   ```

2. **Create Azure Container Registry**

   ```bash
   az acr create --resource-group ptchampion-rg \
     --name ptchampionregistry --sku Standard --admin-enabled true
   ```

3. **Create Azure Database for PostgreSQL**

   ```bash
   az postgres flexible-server create \
     --resource-group ptchampion-rg \
     --name ptchampion-db \
     --admin-user dbadmin \
     --admin-password "<secure-password>" \
     --sku-name Standard_B1ms \
     --tier Burstable \
     --storage-size 32 \
     --backup-retention 7
   ```

4. **Create Azure Cache for Redis**

   ```bash
   az redis create \
     --resource-group ptchampion-rg \
     --name ptchampion-redis \
     --location eastus \
     --sku Basic \
     --vm-size C0
   ```

5. **Create Storage Account for Web Frontend**

   ```bash
   az storage account create \
     --name ptchampionweb \
     --resource-group ptchampion-rg \
     --location eastus \
     --sku Standard_LRS \
     --https-only true \
     --min-tls-version TLS1_2
   
   # Enable static website hosting
   az storage blob service-properties update \
     --account-name ptchampionweb \
     --static-website \
     --index-document index.html \
     --404-document index.html
   ```

6. **Create App Service Plan and Web App for API**

   ```bash
   # Create App Service Plan
   az appservice plan create \
     --name ptchampion-plan \
     --resource-group ptchampion-rg \
     --is-linux \
     --sku P1v2
   
   # Create Web App for Containers
   az webapp create \
     --resource-group ptchampion-rg \
     --plan ptchampion-plan \
     --name ptchampion-api \
     --deployment-container-image-name ptchampionregistry.azurecr.io/ptchampion-api:latest
   ```

7. **Create Azure Front Door**

   ```bash
   # Create Front Door Profile
   az afd profile create \
     --resource-group ptchampion-rg \
     --profile-name ptchampion-frontend \
     --sku Standard_AzureFrontDoor
   
   # Create Endpoint
   az afd endpoint create \
     --resource-group ptchampion-rg \
     --profile-name ptchampion-frontend \
     --endpoint-name ptchampion \
     --enabled-state Enabled
   ```

8. **Set up Application Insights**

   ```bash
   az monitor app-insights component create \
     --app ptchampion-insights \
     --location eastus \
     --resource-group ptchampion-rg \
     --application-type web
   ```

## Configuring GitHub Actions for Deployment

1. **Add GitHub Secrets**

   Add the following secrets to your GitHub repository:

   - `AZURE_CLIENT_ID`: From the service principal creation
   - `AZURE_TENANT_ID`: From the service principal creation
   - `AZURE_SUBSCRIPTION_ID`: Your Azure subscription ID
   - `ACR_NAME`: Your container registry name (e.g., ptchampionregistry)
   - `STORAGE_ACCOUNT_STAGING`: The storage account name for staging
   - `STORAGE_ACCOUNT_PROD`: The storage account name for production
   - `FRONT_DOOR_ENDPOINT_STAGING`: The Front Door endpoint name for staging
   - `FRONT_DOOR_ENDPOINT_PROD`: The Front Door endpoint name for production

2. **Enable GitHub Actions Workflow**

   The continuous deployment workflow is already configured in `.github/workflows/continuous-deployment.yml`. Make sure it's enabled in your repository.

## Database Migrations

After the first deployment, you need to run the initial database migrations:

```bash
# Set up connection to the Azure Database for PostgreSQL
export DB_HOST=ptchampion-db.postgres.database.azure.com
export DB_USER=dbadmin
export DB_PASSWORD=your-password
export DB_NAME=ptchampion
export DB_PORT=5432

# Run migrations
make migrate-up
```

## Custom Domain Configuration

1. **Configure Custom Domain in Azure DNS**

   ```bash
   # Create DNS Zone if not exists
   az network dns zone create \
     --resource-group ptchampion-rg \
     --name ptchampion.com
   
   # Add CNAME record for the Front Door endpoint
   az network dns record-set cname create \
     --resource-group ptchampion-rg \
     --zone-name ptchampion.com \
     --name www
   
   az network dns record-set cname set-record \
     --resource-group ptchampion-rg \
     --zone-name ptchampion.com \
     --record-set-name www \
     --cname ptchampion.z01.azurefd.net
   ```

2. **Add Custom Domain to Front Door**

   ```bash
   # Add custom domain
   az afd custom-domain create \
     --resource-group ptchampion-rg \
     --profile-name ptchampion-frontend \
     --custom-domain-name ptchampion-custom-domain \
     --host-name www.ptchampion.com
   
   # Enable HTTPS with managed certificate
   az afd custom-domain update \
     --resource-group ptchampion-rg \
     --profile-name ptchampion-frontend \
     --custom-domain-name ptchampion-custom-domain \
     --minimum-tls-version TLS12 \
     --certificate-type ManagedCertificate
   ```

## Monitoring and Logging

1. **View Application Logs**

   ```bash
   # View App Service logs
   az webapp log tail --resource-group ptchampion-rg --name ptchampion-api
   ```

2. **Set up Alerts**

   ```bash
   # Create action group for alerts
   az monitor action-group create \
     --resource-group ptchampion-rg \
     --name ptchampion-alerts \
     --short-name ptchamp \
     --email-receiver admin-name admin@example.com
   
   # Create alert for high CPU usage
   az monitor metrics alert create \
     --resource-group ptchampion-rg \
     --name "High CPU Alert" \
     --scopes $(az webapp show --resource-group ptchampion-rg --name ptchampion-api --query id -o tsv) \
     --condition "avg Percentage CPU > 80" \
     --window-size 5m \
     --evaluation-frequency 1m \
     --action $(az monitor action-group show --resource-group ptchampion-rg --name ptchampion-alerts --query id -o tsv)
   ```

3. **Application Insights**

   Access comprehensive monitoring, logs, and traces through the Azure Portal at:
   `https://portal.azure.com/#resource/subscriptions/SUBSCRIPTION_ID/resourceGroups/ptchampion-rg/providers/microsoft.insights/components/ptchampion-insights`

## Scaling

1. **Scale App Service Plan**

   ```bash
   # Scale out to more instances
   az appservice plan update \
     --resource-group ptchampion-rg \
     --name ptchampion-plan \
     --number-of-workers 3
   
   # Configure autoscaling
   az monitor autoscale create \
     --resource-group ptchampion-rg \
     --resource ptchampion-plan \
     --resource-type Microsoft.Web/serverfarms \
     --name autoscale-plan \
     --min-count 2 \
     --max-count 5 \
     --count 2
   
   # Add a scale rule
   az monitor autoscale rule create \
     --resource-group ptchampion-rg \
     --autoscale-name autoscale-plan \
     --scale out 1 \
     --condition "Percentage CPU > 70 avg 10m"
   ```

2. **Scale Database**

   ```bash
   # Scale up the database
   az postgres flexible-server update \
     --resource-group ptchampion-rg \
     --name ptchampion-db \
     --sku-name Standard_D2s_v3
   ```

## Rollback Procedure

In case of deployment issues:

1. **Rollback to Previous Container Image**

   ```bash
   # Get previous image tags
   az acr repository show-tags \
     --name ptchampionregistry \
     --repository ptchampion-api \
     --orderby time_desc \
     --output table
   
   # Update App Service to use previous image
   az webapp config container set \
     --resource-group ptchampion-rg \
     --name ptchampion-api \
     --docker-custom-image-name ptchampionregistry.azurecr.io/ptchampion-api:previous-tag
   ```

2. **Rollback Database (if needed)**

   ```bash
   # Restore from point-in-time
   az postgres flexible-server restore \
     --resource-group ptchampion-rg \
     --name ptchampion-db-restored \
     --source-server ptchampion-db \
     --restore-time "2023-06-20T13:00:00Z"
   ```

3. **Rollback Web Frontend**

   ```bash
   # Get previous deployment package
   # Update the static website content
   az storage blob upload-batch \
     --source previous-web-build \
     --destination '$web' \
     --account-name ptchampionweb
   
   # Purge Front Door cache
   az afd endpoint purge \
     --resource-group ptchampion-rg \
     --profile-name ptchampion-frontend \
     --endpoint-name ptchampion \
     --content-paths "/*"
   ```

## Troubleshooting

### Common Issues

1. **Container fails to start**
   - Check container logs: `az webapp log tail --resource-group ptchampion-rg --name ptchampion-api`
   - Verify environment variables are correctly set in App Service Configuration
   - Check container health probe configuration

2. **Database connection issues**
   - Verify firewall rules: `az postgres flexible-server firewall-rule list --resource-group ptchampion-rg --name ptchampion-db`
   - Check connection string format and credentials
   - Verify VNET integration if using private endpoints

3. **Front Door routing issues**
   - Check origin group configuration
   - Verify routes and patterns
   - Check custom domain validation status

## Maintenance

### Regular Maintenance Tasks

1. **Update SSL certificates** (if not using managed certificates)
2. **Review and optimize database performance**
3. **Check for resource usage optimization**
4. **Regularly review security advisories from Azure Security Center**
5. **Perform quarterly disaster recovery drills**

For further assistance or questions, contact the DevOps team or consult Azure documentation. 