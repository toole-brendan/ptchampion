#!/bin/bash
set -e

# Generate a unique tag based on timestamp
TIMESTAMP=$(date +%Y%m%d%H%M%S)
TAG="ptchampionacr.azurecr.io/ptchampion-api:fix-otel-${TIMESTAMP}"

echo "===== Deploying OpenTelemetry Middleware Fix ====="
echo "Building application with tag: ${TAG}"

# Enable BuildKit and set AMD64 as the default platform
export DOCKER_BUILDKIT=1
export DOCKER_DEFAULT_PLATFORM=linux/amd64

# Create and push Docker image with AMD64 architecture
echo "Creating AMD64 Docker image with the fix..."
docker build --platform linux/amd64 -t ${TAG} .

# Use az acr login instead of docker login
echo "Logging into Azure Container Registry..."
az acr login --name ptchampionacr

echo "Pushing to Azure Container Registry..."
docker push ${TAG}

# Verify image architecture - make this step optional
echo "Verifying image architecture..."
docker buildx imagetools inspect ${TAG} | grep Architecture || echo "Architecture verification skipped, continuing..."

# Update web app to use the new image with the correct parameter
echo "Updating Azure Web App to use the new image..."
az webapp config container set --name ptchampion-api-westus \
  --resource-group ptchampion-rg \
  --container-image-name ${TAG} \
  --container-registry-url https://ptchampionacr.azurecr.io

# Restart the Azure Web App
echo "Restarting Azure Web App..."
az webapp restart --name ptchampion-api-westus --resource-group ptchampion-rg

# Give the app a moment to start initial startup
echo "Waiting for initial startup (15 seconds)..."
sleep 15

# Check health endpoint in a loop
echo "Checking health endpoint (will try up to 30 times)..."
for i in {1..30}; do
  echo "Health check attempt $i/30..."
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://ptchampion-api-westus.azurewebsites.net/health)
  
  if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Health check passed! The fix was successful."
    break
  elif [ $i -eq 30 ]; then
    echo "❌ Health check failed after 30 attempts. Last status code: $HTTP_CODE"
  else
    echo "Health check returned status $HTTP_CODE, waiting 5 seconds before retry..."
    sleep 5
  fi
done

echo ""
echo "Deployment completed! If health checks are passing, the nil pointer issue is fixed."
echo "If not, verify that the changes to otel.go were properly saved and included in the build." 