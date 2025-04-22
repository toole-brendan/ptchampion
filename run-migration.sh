#!/bin/bash
set -e

echo "🔧 Running database migration for column fixes..."

# Use the Azure PostgreSQL credentials
DB_HOST="ptchampion-db.postgres.database.azure.com"
DB_PORT="5432"
DB_USER="ptadmin"
DB_NAME="ptchampion"
DB_SSL_MODE="require"

# Prompt for password (more secure than hardcoding)
echo "Enter the database password for $DB_USER@$DB_HOST:"
read -s DB_PASSWORD
echo

# Construct the connection string
DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=${DB_SSL_MODE}"

# Execute the migration file
echo "🔧 Executing migration SQL against database..."
echo "👉 Using database URL: ${DATABASE_URL//:.*@/:***@}"  # Mask the password in logs

# Run the SQL file against the database
psql "$DATABASE_URL" -f sql/migrations/20250421_add_password_hash_column.sql

echo "✅ Migration successfully applied!"
echo "🔄 Now deploying updated code..."

# Call the deployment script
TAG="ptchampionacr.azurecr.io/ptchampion-api:fix-db-schema-$(date +%Y%m%d%H%M%S)"
echo "🔧 Building and deploying with tag: $TAG"

# Build and push Docker image
export DOCKER_BUILDKIT=1
export DOCKER_DEFAULT_PLATFORM=linux/amd64
docker build --platform linux/amd64 -t ${TAG} .

# Log into Azure Container Registry
az acr login --name ptchampionacr

# Push the image
docker push ${TAG}

# Update the web app
az webapp config container set --name ptchampion-api-westus \
  --resource-group ptchampion-rg \
  --container-image-name ${TAG} \
  --container-registry-url https://ptchampionacr.azurecr.io

# Restart the webapp
az webapp restart --name ptchampion-api-westus --resource-group ptchampion-rg

echo "✅ Deployment completed!"
echo "🔍 Monitor the logs for any errors:"
echo "   az webapp log tail --name ptchampion-api-westus --resource-group ptchampion-rg --provider container" 