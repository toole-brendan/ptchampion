#!/bin/bash
set -e

# Configuration
TIMESTAMP=$(date +%Y%m%d%H%M%S)
TAG="ptchampionacr.azurecr.io/ptchampion-api:deploy-${TIMESTAMP}"
RESOURCE_GROUP="ptchampion-rg"
APP_SERVICE_NAME="ptchampion-api-westus"
STORAGE_ACCOUNT="ptchampionweb"
FRONT_DOOR_PROFILE="ptchampion-frontend"
FRONT_DOOR_ENDPOINT="ptchampion"
DB_HOST="ptchampion-db.postgres.database.azure.com"
DB_NAME="ptchampion"
DB_USER="ptadmin"

# Prompt for database password securely
echo "Enter database password: "
read -s DB_PASSWORD
echo ""

echo "===== PT Champion Deployment ====="
echo "This script will:"
echo "1. Apply database schema fixes"
echo "2. Build and deploy the backend API"
echo "3. Build and deploy the frontend"
echo ""
echo "Starting deployment with tag: ${TAG}"

# Step 1: Apply database schema fixes
echo "===== Step 1: Applying database schema fixes ====="
echo "Running fix_register_endpoint.sql..."
PGPASSWORD="${DB_PASSWORD}" psql "host=${DB_HOST} port=5432 dbname=${DB_NAME} user=${DB_USER} sslmode=require" -f fix_register_endpoint.sql

echo "Running fix_db_schema_all_columns.sql..."
PGPASSWORD="${DB_PASSWORD}" psql "host=${DB_HOST} port=5432 dbname=${DB_NAME} user=${DB_USER} sslmode=require" -f fix_db_schema_all_columns.sql

# Step 2: Build and deploy the backend API
echo "===== Step 2: Building and deploying backend API ====="
echo "Setting up Docker for AMD64 architecture..."
export DOCKER_BUILDKIT=1
export DOCKER_DEFAULT_PLATFORM=linux/amd64

echo "Building Docker image with proper architecture..."
docker build --platform linux/amd64 -t ${TAG} .

echo "Logging into Azure Container Registry..."
az acr login --name ptchampionacr

echo "Pushing image to registry..."
docker push ${TAG}

echo "Updating App Service to use new image..."
az webapp config container set --name ${APP_SERVICE_NAME} \
  --resource-group ${RESOURCE_GROUP} \
  --container-image-name ${TAG} \
  --container-registry-url https://ptchampionacr.azurecr.io

echo "Restarting App Service..."
az webapp restart --name ${APP_SERVICE_NAME} --resource-group ${RESOURCE_GROUP}

# Step 3: Build and deploy the frontend
echo "===== Step 3: Building and deploying frontend ====="

echo "Building frontend..."
cd web
npm install
npm run build
cd ..

echo "Deploying to Azure Storage..."
az storage blob upload-batch \
  --source web/dist \
  --destination '$web' \
  --account-name ${STORAGE_ACCOUNT} \
  --overwrite

echo "Purging CDN cache..."
az afd endpoint purge \
  --resource-group ${RESOURCE_GROUP} \
  --profile-name ${FRONT_DOOR_PROFILE} \
  --endpoint-name ${FRONT_DOOR_ENDPOINT} \
  --content-paths "/*"

# Step 4: Verify deployment
echo "===== Step 4: Verifying deployment ====="
echo "Waiting for services to stabilize (15 seconds)..."
sleep 15

echo "Checking backend health..."
BACKEND_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "https://${APP_SERVICE_NAME}.azurewebsites.net/health")
if [ "$BACKEND_HEALTH" = "200" ]; then
  echo "✅ Backend health check passed!"
else
  echo "❌ Backend health check failed with status: $BACKEND_HEALTH"
fi

echo "Checking frontend..."
FRONTEND_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "https://www.ptchampion.ai")
if [ "$FRONTEND_HEALTH" = "200" ]; then
  echo "✅ Frontend check passed!"
else
  echo "❌ Frontend check failed with status: $FRONTEND_HEALTH"
fi

echo ""
echo "===== Deployment Complete ====="
echo "Deployment tag: ${TAG}"
echo ""
echo "To check backend logs: az webapp log tail --name ${APP_SERVICE_NAME} --resource-group ${RESOURCE_GROUP}"
echo "" 