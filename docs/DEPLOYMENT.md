# PT Champion Deployment Guide

This guide explains how to deploy the PT Champion application to production.

## Architecture Overview

PT Champion consists of two main components:
1. **Web Frontend** - React-based PWA deployed to Azure Storage Static Website
2. **Backend API** - Go application deployed as a containerized app to Azure App Service

Both components are served via Azure Front Door CDN at the domain `ptchampion.ai`.

## Automated Deployment

We have an automated GitHub workflow to streamline the deployment process. This workflow can deploy both the frontend and backend components in a single operation.

### Using the Deployment Workflow

1. Go to the GitHub repository Actions tab
2. Select the "Deploy to Production" workflow
3. Click "Run workflow" dropdown button
4. Configure the deployment options:
   - **Deploy frontend**: Select this option to build and deploy the web frontend
   - **Deploy backend**: Select this option to build and deploy the backend API
5. Click "Run workflow" to start the deployment process

The workflow performs these steps:
- Builds the web frontend and/or backend components
- Deploys them to their respective Azure services
- Purges the Front Door cache to ensure the latest content is served
- Conducts health checks to verify both components are working correctly

### Deployment Status

You can monitor the deployment progress in the Actions tab. After successful deployment, the workflow will conduct health checks to ensure everything is working properly.

## Manual Deployment (if needed)

### Web Frontend

1. Build the web frontend:
   ```bash
   cd web
   npm install
   npm run build:production
   ```

2. Upload the build files to Azure Storage:
   ```bash
   az storage blob upload-batch \
     -s dist \
     -d '$web' \
     --account-name ptchampionweb \
     --overwrite
   ```

3. Purge the Front Door cache:
   ```bash
   az afd endpoint purge \
     --resource-group ptchampion-rg \
     --profile-name ptchampion-frontend \
     --endpoint-name ptchampion \
     --content-paths "/*"
   ```

### Backend API

1. Build and push Docker image:
   ```bash
   # Login to Azure Container Registry
   az acr login --name <ACR_NAME>
   
   # Build and tag image
   docker build -t <ACR_NAME>.azurecr.io/ptchampion-api:latest .
   
   # Push image
   docker push <ACR_NAME>.azurecr.io/ptchampion-api:latest
   ```

2. Deploy to App Service:
   ```bash
   az webapp config container set \
     --resource-group ptchampion-rg \
     --name ptchampion-api-westus \
     --docker-custom-image-name <ACR_NAME>.azurecr.io/ptchampion-api:latest
   ```

3. Restart the App Service:
   ```bash
   az webapp restart \
     --resource-group ptchampion-rg \
     --name ptchampion-api-westus
   ```

## Troubleshooting

### Web Frontend Issues

1. Check if files were properly uploaded to Azure Storage:
   ```bash
   az storage blob list \
     --account-name ptchampionweb \
     --container-name '$web' \
     --output table
   ```

2. Verify the Front Door cache was purged successfully
3. Check browser console for any JavaScript errors or network issues

### Backend API Issues

1. Check the App Service logs:
   ```bash
   az webapp log tail \
     --resource-group ptchampion-rg \
     --name ptchampion-api-westus
   ```

2. Verify the container image is available and correctly tagged in ACR
3. Ensure environment variables are properly configured in App Service settings
4. Check the health endpoint: `https://ptchampion.ai/api/v1/health`

## Post-Deployment Verification

After deployment, verify these endpoints are working:

1. Web frontend: `https://ptchampion.ai`
2. Backend API health: `https://ptchampion.ai/api/v1/health`

Additionally, perform basic functional testing to ensure key application features work correctly. 