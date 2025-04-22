#!/bin/bash
set -e

echo "🔧 Fixing missing columns in production database..."

# Use the Azure PostgreSQL credentials
DB_HOST="ptchampion-db.postgres.database.azure.com"
DB_PORT="5432"
DB_USER="ptadmin"
DB_NAME="ptchampion"
DB_SSL_MODE="require"

# Get password from Azure Key Vault
echo "🔐 Retrieving database password from Azure Key Vault..."
echo "Ensuring you're logged into Azure..."
az account show > /dev/null || az login

# Retrieve the password from Key Vault
DB_PASSWORD=$(az keyvault secret show --name "DB-PASSWORD" --vault-name "ptchampion-kv" --query "value" -o tsv)
if [ -z "$DB_PASSWORD" ]; then
  echo "❌ Failed to retrieve database password from Key Vault"
  echo "Please make sure the secret 'DB-PASSWORD' exists in 'ptchampion-kv' vault and you have access to it."
  exit 1
fi
echo "✅ Password retrieved successfully"

# Construct the connection string
DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=${DB_SSL_MODE}"

# Create a temporary SQL file with the fixes
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

-- Verify columns exist
SELECT
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'display_name') as has_display_name,
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'profile_picture_url') as has_profile_picture_url,
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'location') as has_location,
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'latitude') as has_latitude,
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'longitude') as has_longitude;
EOF

# Execute the SQL file against the database
echo "🔧 Executing fixes against database..."
echo "👉 Using database URL: ${DATABASE_URL//:.*@/:***@}"  # Mask the password in logs

# Run the SQL file against the database
psql "$DATABASE_URL" -f /tmp/fix_columns.sql

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