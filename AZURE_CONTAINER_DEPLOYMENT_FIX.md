# Azure Container Deployment Fix Guide

This guide provides step-by-step instructions for fixing Azure App Service container deployment issues for PT Champion.

## Problem Analysis

Based on the logs, the container deployment is failing due to several issues:

1. **Database connection problems** - The container fails to connect to the PostgreSQL database
2. **Startup timeout** - The container exceeds the default 230-second startup timeout
3. **SSL mode configuration** - Mismatch between expected SSL mode (require vs disable)
4. **Health check issues** - The container health check endpoint is not responding properly
5. **Container image pull issues** - Potential ACR authentication problems

## Fix Instructions

### Step 1: Fix Container Configuration

The `fix-container-config.sh` script has been created to configure the Azure App Service properly.

```bash
# Make the script executable
chmod +x fix-container-config.sh

# Run the script to fix App Service configuration
./fix-container-config.sh
```

This script:
- Sets the container startup timeout to 600 seconds
- Enables persistent storage
- Adds troubleshooting flags
- Configures managed identity for ACR access
- Updates container configuration
- Sets WEBSITES_PORT to 8080

### Step 2: Rebuild and Deploy the Container

The entrypoint script and Dockerfile have been updated to add better error handling and health check support.

```bash
# Make sure all scripts are executable
chmod +x scripts/entrypoint.sh
chmod +x deploy-to-azure.sh

# Build and deploy the container
./deploy-to-azure.sh
```

### Step 3: Monitor Deployment

Use these commands to monitor the deployment:

```bash
# View live logs
az webapp log tail --name ptchampion-api-westus --resource-group ptchampion-rg

# Check health endpoint after a few minutes
curl -v https://ptchampion-api-westus.azurewebsites.net/health
```

### Step 4: Use Debug Tools if Still Failing

If the container still fails to start, use the debug-container.sh script:

```bash
# Make the script executable
chmod +x debug-container.sh

# Run the debug script
./debug-container.sh
```

This will:
- Download and analyze container logs
- Check for configuration issues
- Suggest specific fixes

## Troubleshooting Specific Issues

### Database Connection Problems

1. Verify database details:
   ```bash
   az webapp config appsettings list --name ptchampion-api-westus --resource-group ptchampion-rg --query "[?name=='DB_HOST' || name=='DB_PORT' || name=='DB_USER' || name=='DB_NAME' || name=='DB_SSL_MODE']"
   ```

2. Test connection from your local machine:
   ```bash
   PGPASSWORD=your_password psql -h your_db_host -p your_db_port -U your_db_user -d your_db_name -c "SELECT 1"
   ```

### Container Startup Timeout

The default timeout is 230 seconds, which may not be enough if database migrations take time. The fix script sets this to 600 seconds.

### SSL Mode Configuration

The updated entrypoint script now respects the DB_SSL_MODE environment variable.

### ACR Authentication

If the container fails to pull, check:
1. ACR authentication
2. Managed identity configuration
3. AcrPull role assignment

## What Changed

### entrypoint.sh Changes:
- Added support for DB_SSL_MODE environment variable
- Improved error handling for database connections
- Added a simple health check endpoint using netcat
- Added more verbose logging

### Dockerfile Changes:
- Added netcat-openbsd package for the health check server

## Production Ready Considerations

Once the container is stable:

1. Remove troubleshooting flags:
   ```bash
   az webapp config appsettings set --name ptchampion-api-westus --resource-group ptchampion-rg --settings IGNORE_MIGRATION_FAILURE=false IGNORE_DB_CONNECTION_FAILURE=false
   ```

2. Consider implementing a more robust health check in your application code

3. Set up monitoring and alerts for the App Service

4. Document the deployment process and troubleshooting steps for the team
