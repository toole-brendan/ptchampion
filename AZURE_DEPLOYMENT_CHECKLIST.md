# Azure Deployment Checklist for PT Champion

This checklist provides step-by-step instructions for deploying the PT Champion application to Azure, addressing common issues, and verifying a successful deployment.

## Backend Deployment

### 1. Pre-deployment Checks
- [ ] Ensure CORS configuration in `internal/api/middleware/security.go` includes all required domains:
  - `https://ptchampion.com`
  - `https://staging.ptchampion.com`
  - `https://www.ptchampion.ai`
  - `http://localhost:5173` (development only)
- [ ] Verify CSP headers in `SecurityHeaders()` middleware allow connections to your API endpoint
- [ ] Run all tests locally to ensure the application is working properly
- [ ] Check that all environment variables are properly defined in your Azure App Service settings

### 2. Build and Deploy Backend
- [ ] Build the Docker image: `docker build -t ptchampion-api .`
- [ ] Tag the image for ACR: `docker tag ptchampion-api ptchampionacr.azurecr.io/ptchampion-api:latest`
- [ ] Push the image to ACR: `docker push ptchampionacr.azurecr.io/ptchampion-api:latest`
- [ ] Deploy to Azure App Service:
  ```bash
  az webapp config container set --name ptchampion-api-westus \
    --resource-group ptchampion-rg \
    --docker-custom-image-name ptchampionacr.azurecr.io/ptchampion-api:latest \
    --docker-registry-server-url https://ptchampionacr.azurecr.io
  ```

### 3. Post-deployment Backend Verification
- [ ] Check health endpoint: `curl https://ptchampion-api-westus.azurewebsites.net/health`
- [ ] Verify logs for any errors: `az webapp log tail --name ptchampion-api-westus --resource-group ptchampion-rg`
- [ ] Test a public endpoint (such as version or info endpoint)
- [ ] Check if the CORS preflight request works from your domain

## Frontend Deployment

### 1. Pre-deployment Checks
- [ ] Ensure `web/src/lib/config.ts` has the correct API URL for production
- [ ] Update PWA configuration in `web/vite.config.ts` to use the correct API URL pattern
- [ ] Verify all static assets (fonts, icons, etc.) are included in the build
- [ ] Ensure service worker is properly configured

### 2. Build and Deploy Frontend
- [ ] Install dependencies: `cd web && npm install`
- [ ] Build the application: `npm run build`
- [ ] Deploy to Azure Storage:
  ```bash
  az storage blob upload-batch \
    --source web/dist \
    --destination '$web' \
    --account-name ptchampionweb \
    --overwrite
  ```
- [ ] Purge CDN cache if using Azure Front Door:
  ```bash
  az afd endpoint purge \
    --resource-group ptchampion-rg \
    --profile-name ptchampion-frontend \
    --endpoint-name ptchampion \
    --content-paths "/*"
  ```

### 3. Post-deployment Frontend Verification
- [ ] Open the website in a browser and check for any console errors
- [ ] Verify all static assets load properly (no 404 errors)
- [ ] Test login/registration functionality
- [ ] Test other key features of the application

## Troubleshooting Common Issues

### CORS Issues
- Make sure the backend's CORS configuration includes your frontend domain
- Check Network tab in browser dev tools for CORS preflight failures
- Verify the `Access-Control-Allow-Origin` header is present in responses

### 404 Errors for Static Assets
- Ensure all files were uploaded to Azure Storage
- Check if the path in the URL matches the path in the storage container
- Verify Azure Storage static website hosting is configured correctly

### API Connection Failures
- Confirm the API URL in `config.ts` matches your actual backend endpoint
- Check if the API is accessible by directly visiting the URL in a browser
- Verify SSL certificates are valid and not causing connection issues

### Service Worker Issues
- Ensure serviceWorker.js is included in the build and uploaded to storage
- Check if the service worker registration code is executed in the browser
- Verify the browser supports service workers

## Deployment Verification Script

For a quick check of your deployment, you can run:

```bash
#!/bin/bash

# Check backend health
echo "Checking backend health..."
curl -s https://ptchampion-api-westus.azurewebsites.net/health | grep "healthy" || echo "Backend health check failed"

# Check frontend loading
echo "Checking frontend loading..."
curl -s -I https://www.ptchampion.ai | grep "200" || echo "Frontend loading check failed"

# Check for critical assets
echo "Checking critical assets..."
curl -s -I https://www.ptchampion.ai/serviceWorker.js | grep "200" || echo "Service worker missing"
curl -s -I https://www.ptchampion.ai/index.html | grep "200" || echo "Index.html missing"

echo "Deployment verification complete!"
```

## Production Readiness Checks

- [ ] API responses are properly cached in Redis
- [ ] Database connections are using connection pooling
- [ ] Error monitoring is enabled (Application Insights)
- [ ] Health checks are configured on all critical endpoints
- [ ] SSL is properly configured and certificates are valid
- [ ] Database backups are enabled and tested
- [ ] Logging is enabled and stored/monitored appropriately
