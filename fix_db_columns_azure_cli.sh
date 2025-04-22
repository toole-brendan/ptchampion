#!/bin/bash
set -e

echo "🔧 Fixing missing columns in production database using Azure CLI..."

# Define Azure resource details
RESOURCE_GROUP="ptchampion-rg"
SERVER_NAME="ptchampion-db"
DATABASE_NAME="ptchampion"
ADMIN_USER="ptadmin"

# Ensure logged into Azure
echo "Ensuring you're logged into Azure..."
az account show > /dev/null || az login

# Configure extension for dynamic installation without prompt
az config set extension.use_dynamic_install=yes_without_prompt
az config set extension.dynamic_install_allow_preview=true

# Get password from Azure Key Vault
echo "🔐 Retrieving database password from Azure Key Vault..."
ADMIN_PASSWORD=$(az keyvault secret show --name "DB-PASSWORD" --vault-name "ptchampion-kv" --query "value" -o tsv)
if [ -z "$ADMIN_PASSWORD" ]; then
  # If Key Vault retrieval fails, prompt for password
  echo "Failed to retrieve password from Key Vault. Please enter it manually:"
  read -s ADMIN_PASSWORD
  echo
  if [ -z "$ADMIN_PASSWORD" ]; then
    echo "❌ No password provided. Exiting."
    exit 1
  fi
fi

# Create the SQL query file
cat > /tmp/fix_columns.sql << EOF
-- Fix missing columns in users table

-- Add display_name column if it doesn't exist
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'users' AND column_name = 'display_name') THEN
        ALTER TABLE users ADD COLUMN display_name VARCHAR(255);
        RAISE NOTICE 'Added display_name column';
    ELSE
        RAISE NOTICE 'display_name column already exists';
    END IF;
END \$\$;

-- Add profile_picture_url column if it doesn't exist
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'users' AND column_name = 'profile_picture_url') THEN
        ALTER TABLE users ADD COLUMN profile_picture_url VARCHAR(1024);
        RAISE NOTICE 'Added profile_picture_url column';
    ELSE
        RAISE NOTICE 'profile_picture_url column already exists';
    END IF;
END \$\$;

-- Add location column if it doesn't exist
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'users' AND column_name = 'location') THEN
        ALTER TABLE users ADD COLUMN location VARCHAR(255);
        RAISE NOTICE 'Added location column';
    ELSE
        RAISE NOTICE 'location column already exists';
    END IF;
END \$\$;

-- Add latitude column if it doesn't exist
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'users' AND column_name = 'latitude') THEN
        ALTER TABLE users ADD COLUMN latitude VARCHAR(50);
        RAISE NOTICE 'Added latitude column';
    ELSE
        RAISE NOTICE 'latitude column already exists';
    END IF;
END \$\$;

-- Add longitude column if it doesn't exist
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'users' AND column_name = 'longitude') THEN
        ALTER TABLE users ADD COLUMN longitude VARCHAR(50);
        RAISE NOTICE 'Added longitude column';
    ELSE
        RAISE NOTICE 'longitude column already exists';
    END IF;
END \$\$;
EOF

echo "🔧 Executing SQL commands via Azure CLI..."

# Execute the SQL commands via Azure CLI
az postgres flexible-server execute \
  --resource-group "$RESOURCE_GROUP" \
  --name "$SERVER_NAME" \
  --database-name "$DATABASE_NAME" \
  --admin-user "$ADMIN_USER" \
  --admin-password "$ADMIN_PASSWORD" \
  --file-path "/tmp/fix_columns.sql"

# Verify columns exist
echo "🔍 Verifying columns were added successfully..."
az postgres flexible-server execute \
  --resource-group "$RESOURCE_GROUP" \
  --name "$SERVER_NAME" \
  --database-name "$DATABASE_NAME" \
  --admin-user "$ADMIN_USER" \
  --admin-password "$ADMIN_PASSWORD" \
  --querytext "SELECT
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'display_name') as has_display_name,
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'profile_picture_url') as has_profile_picture_url,
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'location') as has_location,
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'latitude') as has_latitude,
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'longitude') as has_longitude;"

echo "✅ Database fixes applied!"
echo "🧪 Testing with a registration request..."

# Wait a moment for changes to propagate
sleep 2

# Make a test registration request to verify fix
curl -i -X POST \
  https://ptchampion-api-westus.azurewebsites.net/api/v1/auth/register \
  -H 'Content-Type: application/json' \
  -d '{
    "username": "test_user_'$(date +%s)'",
    "password": "TestPassword123!",
    "displayName": "Test User"
  }'

# Clean up
rm /tmp/fix_columns.sql

echo ""
echo "✅ Fix completed! Check the API response above - if you see HTTP 200/201, the fix worked!" 