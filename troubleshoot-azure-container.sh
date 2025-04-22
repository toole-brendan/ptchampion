#!/bin/bash
# PT Champion Container Deployment Troubleshooter
# This script helps diagnose and fix common issues with the container deployment to Azure App Service
# Run this script when the Azure App Service fails to start or shows container-related errors

set -e  # Exit on any error

# Configuration
RESOURCE_GROUP="ptchampion-rg"
ACR_NAME="ptchampionacr"
WEBAPP_NAME="ptchampion-api-westus"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to display status messages
status() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

# Function to display warning messages
warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to display error messages
error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check for required tools
status "Checking prerequisites..."
for cmd in az docker curl jq; do
  if ! command_exists $cmd; then
    warning "$cmd is not installed. Some checks may fail."
  fi
done

# Check if logged in to Azure
status "Checking Azure login..."
az account show > /dev/null 2>&1 || { 
  error "Not logged in to Azure. Please run 'az login' first."
  exit 1
}

# Verify Azure resources exist
status "Verifying Azure resources..."
az group show --name $RESOURCE_GROUP > /dev/null 2>&1 || {
  error "Resource group $RESOURCE_GROUP does not exist."
  exit 1
}

# 1. Check ACR and image status
status "==== Checking ACR Status ===="
az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP > /dev/null 2>&1 || {
  error "ACR $ACR_NAME does not exist in resource group $RESOURCE_GROUP"
  exit 1
}
status "✅ ACR $ACR_NAME exists"

# Check if image exists
status "Checking if container image exists in ACR..."
az acr repository show --name $ACR_NAME --image ptchampion-api:latest > /dev/null 2>&1 || {
  warning "⚠️ Container image 'ptchampion-api:latest' not found in ACR"
  
  # Offer to rebuild and push the image
  read -p "Do you want to rebuild and push the image? (y/n): " REBUILD
  if [[ $REBUILD == "y" || $REBUILD == "Y" ]]; then
    status "Building Docker image..."
    docker build -t ptchampion-api .
    
    status "Logging in to ACR..."
    az acr login --name $ACR_NAME
    
    status "Tagging and pushing image..."
    docker tag ptchampion-api $ACR_NAME.azurecr.io/ptchampion-api:latest
    docker push $ACR_NAME.azurecr.io/ptchampion-api:latest
    
    status "Image pushed to ACR"
  else
    status "Skipping image rebuild. Continuing with diagnostics..."
  fi
}

# 2. Check App Service configuration
status "==== Checking App Service Configuration ===="
az webapp show --name $WEBAPP_NAME --resource-group $RESOURCE_GROUP > /dev/null 2>&1 || {
  error "App Service $WEBAPP_NAME does not exist in resource group $RESOURCE_GROUP"
  exit 1
}
status "✅ App Service $WEBAPP_NAME exists"

# Check container configuration
status "Checking container configuration..."
APP_CONFIG=$(az webapp config container show --name $WEBAPP_NAME --resource-group $RESOURCE_GROUP)
echo "$APP_CONFIG" | jq . || echo "$APP_CONFIG"

# Check if pointing to the right registry and image
REGISTRY_URL=$(echo "$APP_CONFIG" | grep -o "registryUrl.*" | cut -d'"' -f3)
IMAGE_NAME=$(echo "$APP_CONFIG" | grep -o "imageName.*" | cut -d'"' -f3)

if [[ "$REGISTRY_URL" != *"$ACR_NAME"* ]]; then
  warning "⚠️ App Service is not configured to use $ACR_NAME.azurecr.io"
  read -p "Fix registry URL configuration? (y/n): " FIX_REGISTRY
  if [[ $FIX_REGISTRY == "y" || $FIX_REGISTRY == "Y" ]]; then
    status "Updating registry configuration..."
    az webapp config container set \
      --name $WEBAPP_NAME \
      --resource-group $RESOURCE_GROUP \
      --docker-registry-server-url https://$ACR_NAME.azurecr.io
  fi
fi

if [[ "$IMAGE_NAME" != *"ptchampion-api:latest"* ]]; then
  warning "⚠️ App Service is not using the expected image: ptchampion-api:latest"
  read -p "Fix image configuration? (y/n): " FIX_IMAGE
  if [[ $FIX_IMAGE == "y" || $FIX_IMAGE == "Y" ]]; then
    status "Updating image configuration..."
    az webapp config container set \
      --name $WEBAPP_NAME \
      --resource-group $RESOURCE_GROUP \
      --docker-custom-image-name $ACR_NAME.azurecr.io/ptchampion-api:latest
  fi
fi

# 3. Check App Service identity for ACR pull
status "==== Checking App Service Identity for ACR Pull ===="
IDENTITY=$(az webapp identity show --name $WEBAPP_NAME --resource-group $RESOURCE_GROUP 2>/dev/null)
if [ -z "$IDENTITY" ]; then
  warning "⚠️ App Service has no managed identity assigned"
  read -p "Assign managed identity? (y/n): " ASSIGN_IDENTITY
  if [[ $ASSIGN_IDENTITY == "y" || $ASSIGN_IDENTITY == "Y" ]]; then
    status "Assigning managed identity..."
    az webapp identity assign --name $WEBAPP_NAME --resource-group $RESOURCE_GROUP
    IDENTITY=$(az webapp identity show --name $WEBAPP_NAME --resource-group $RESOURCE_GROUP)
  fi
fi

if [ -n "$IDENTITY" ]; then
  PRINCIPAL_ID=$(echo $IDENTITY | jq -r .principalId)
  status "Checking ACR pull permissions for principal $PRINCIPAL_ID..."
  
  # Assign AcrPull role if needed
  az role assignment create \
    --assignee $PRINCIPAL_ID \
    --scope $(az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query id -o tsv) \
    --role AcrPull &>/dev/null || status "✅ AcrPull role already assigned"
  
  status "✅ Ensured App Service has AcrPull permission on $ACR_NAME"
fi

# 4. Check App Service environment variables
status "==== Checking App Service Environment Variables ===="
APP_SETTINGS=$(az webapp config appsettings list --name $WEBAPP_NAME --resource-group $RESOURCE_GROUP)
echo "$APP_SETTINGS" | jq . || echo "$APP_SETTINGS"

# Check for required environment variables
REQUIRED_VARS=("DB_HOST" "DB_PORT" "DB_USER" "DB_PASSWORD" "DB_NAME")
MISSING_VARS=()

for VAR in "${REQUIRED_VARS[@]}"; do
  if ! echo "$APP_SETTINGS" | grep -q "\"name\": \"$VAR\""; then
    MISSING_VARS+=("$VAR")
  fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
  warning "⚠️ Missing required environment variables: ${MISSING_VARS[*]}"
  read -p "Would you like to add these variables now? (y/n): " ADD_VARS
  if [[ $ADD_VARS == "y" || $ADD_VARS == "Y" ]]; then
    for VAR in "${MISSING_VARS[@]}"; do
      read -p "Enter value for $VAR: " VAR_VALUE
      az webapp config appsettings set --name $WEBAPP_NAME --resource-group $RESOURCE_GROUP --settings "$VAR=$VAR_VALUE"
    done
  fi
else
  status "✅ All required environment variables are set"
fi

# 5. View recent logs to check for startup issues
status "==== Checking Recent App Service Logs ===="
read -p "View recent logs? This may take a minute to retrieve (y/n): " VIEW_LOGS
if [[ $VIEW_LOGS == "y" || $VIEW_LOGS == "Y" ]]; then
  status "Retrieving logs (last 100 lines). Press Ctrl+C to stop viewing..."
  az webapp log tail --name $WEBAPP_NAME --resource-group $RESOURCE_GROUP --lines 100
fi

# 6. Restart App Service if needed
status "==== App Service Management ===="
read -p "Restart App Service? (y/n): " RESTART_APP
if [[ $RESTART_APP == "y" || $RESTART_APP == "Y" ]]; then
  status "Restarting App Service..."
  az webapp restart --name $WEBAPP_NAME --resource-group $RESOURCE_GROUP
  status "App Service restarted. It may take a few minutes to become available."
fi

# 7. Run the final verification
status "==== Verification ===="
read -p "Run the verification script to check deployment? (y/n): " RUN_VERIFY
if [[ $RUN_VERIFY == "y" || $RUN_VERIFY == "Y" ]]; then
  if [ -f "./verify-deployment.sh" ]; then
    status "Running verification script..."
    bash ./verify-deployment.sh
  else
    error "Verification script not found. Please run the script manually."
  fi
fi

status "==== Troubleshooting Complete ===="
status "If issues persist, please check:"
echo "1. The container's health check configuration (may need to extend startup timeout)"
echo "2. Network connectivity from App Service to database"
echo "3. Application logs for specific application errors"
echo "4. Dockerfile to ensure ENTRYPOINT and CMD are correctly specified"
echo ""
status "Remember: There is NO NGINX in the current configuration. The Go app runs directly."
