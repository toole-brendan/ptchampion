# PT Champion: Azure Deployment Debug Guide

This document provides a detailed guide to diagnosing and fixing deployment issues with your PT Champion application on Azure.

## Current Status

- ✅ **Frontend Accessible**: The frontend is accessible at `https://www.ptchampion.ai`
- ❌ **Backend Issues**: The backend API at `https://ptchampion-api-westus.azurewebsites.net` appears to be having connectivity issues

## Deployment Issues Fixed

1. **CORS Configuration**: Updated to include the `https://www.ptchampion.ai` domain
2. **Content Security Policy**: Updated to allow connections to Azure backend
3. **API URL Configuration**: Fixed inconsistencies in API endpoints
4. **PWA Configuration**: Updated service worker configuration

## Backend Deployment Checklist

If the backend isn't responding, follow these steps to deploy and troubleshoot:

### 1. Manual Azure App Service Deployment

Since our Docker deployment had permission issues, here's how to deploy directly to Azure App Service:

```bash
# 1. Build the Go application locally
go build -o ptchampion-api ./cmd/server

# 2. Compress the binary and necessary files (avoid the ptlogs directory)
zip -r deploy.zip ptchampion-api

# 3. Deploy to Azure using the Azure CLI
az webapp deployment source config-zip --resource-group ptchampion-rg \
  --name ptchampion-api-westus --src deploy.zip
```

### 2. Verify Azure App Service Configuration

1. **Check App Settings in Azure Portal**:
   - Navigate to your App Service in Azure Portal
   - Go to Configuration → Application settings
   - Verify these required environment variables are set:
     - `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`
     - `JWT_SECRET`
     - `APP_PORT` (should be set to 8080)
     - `APP_ENV` (set to production)

2. **Check Deployment Logs**:
   - In Azure Portal, go to your App Service
   - Navigate to Deployment Center → Logs
   - Check for any deployment failures

3. **Review Application Logs**:
   ```bash
   az webapp log tail --name ptchampion-api-westus --resource-group ptchampion-rg
   ```

### 3. Test Backend Connectivity

Use the `api-connectivity-test.html` tool we created:
   - Open the HTML file in your browser
   - Click "Test Health Endpoint" and "Test Ping Endpoint" 
   - Check the results to identify specific issues

## Frontend Deployment Checklist

If you need to update the frontend:

```bash
# 1. Navigate to the web directory
cd web

# 2. Install dependencies
npm install

# 3. Build the application
npm run build

# 4. Deploy to Azure Storage using AZ CLI
az storage blob upload-batch \
  --account-name ptchampionweb \
  --auth-mode login \
  --source dist \
  --destination '$web' \
  --overwrite

# 5. Purge CDN cache
az afd endpoint purge \
  --resource-group ptchampion-rg \
  --profile-name ptchampion-frontend \
  --endpoint-name ptchampion \
  --content-paths "/*"
```

## Specific Backend Issues and Solutions

### 1. Health Endpoint Not Responding

**Problem**: The `/health` endpoint doesn't respond

**Solutions**:
- Check if the App Service is actually running:
  ```bash
  az webapp restart --name ptchampion-api-westus --resource-group ptchampion-rg
  ```
- Verify that port configuration is correct (Azure expects the app to listen on port 8080)
- Check if there are any network security rules blocking access

### 2. Database Connection Issues

**Problem**: Backend can't connect to the database

**Solutions**:
- Verify database connection string in App Settings
- Check if the database firewall allows connections from Azure App Service
- Ensure the database is online and accessible

### 3. CORS Issues

**Problem**: CORS preflight checks failing

**Solutions**:
- We've already updated the CORS configuration in the code
- Make sure the deployed version includes these changes
- Test with the diagnostic tool to verify headers

## Using the Diagnostic Tool

1. Open `api-connectivity-test.html` in your browser
2. Verify the backend URL is set to `https://ptchampion-api-westus.azurewebsites.net`
3. Click the test buttons to diagnose specific issues
4. Results will show in real-time with details about any failures

## Next Steps If Issues Persist

1. **Check Resource Health in Azure**:
   - In Azure Portal, go to your App Service
   - Navigate to Resource Health to check for Azure-side issues

2. **Try a Different Region**:
   - Create a new App Service in a different Azure region
   - Deploy your app to this new service
   - Test connectivity to see if it's a regional issue

3. **Set Up Application Insights**:
   - Enable Application Insights for deeper diagnostics
   - Add the instrumentation key to your app settings
   - Deploy again and check telemetry data

4. **Review Azure Status Page**:
   - Check [Azure Status](https://status.azure.com) for any service outages

## Long-term Solutions

1. **CI/CD Pipeline**: Set up GitHub Actions for automated deployment
2. **Infrastructure as Code**: Use Terraform to manage your Azure resources
3. **Health Monitoring**: Implement Azure Monitor alerts for proactive monitoring
