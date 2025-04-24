#!/bin/bash
set -e

echo "🔧 Applying database schema fixes..."

# Define database connection details
DB_HOST="ptchampion-db.postgres.database.azure.com"
DB_NAME="ptchampion"
DB_USER="ptadmin"

# Prompt for password
echo "Please enter your database password:"
read -s DB_PASSWORD
echo

if [ -z "$DB_PASSWORD" ]; then
  echo "❌ No password provided. Exiting."
  exit 1
fi

# Create the SQL query file
cat > /tmp/fix_schema.sql << EOF
-- Fix for missing display_name column error
ALTER TABLE users ADD COLUMN IF NOT EXISTS display_name TEXT;

-- Fix for missing grade column error
ALTER TABLE user_exercises ADD COLUMN IF NOT EXISTS grade INTEGER;
EOF

echo "🔧 Executing SQL commands via psql..."

# Check if psql is installed
if ! command -v psql &> /dev/null; then
  echo "❌ psql not found. Please install PostgreSQL client tools."
  exit 1
fi

# Execute the SQL commands via psql
PGPASSWORD="$DB_PASSWORD" psql \
  -h "$DB_HOST" \
  -U "$DB_USER" \
  -d "$DB_NAME" \
  -f "/tmp/fix_schema.sql"

# Verify columns exist
echo "🔍 Verifying columns were added successfully..."
PGPASSWORD="$DB_PASSWORD" psql \
  -h "$DB_HOST" \
  -U "$DB_USER" \
  -d "$DB_NAME" \
  -c "SELECT
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'display_name') as has_display_name,
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'user_exercises' AND column_name = 'grade') as has_grade;"

# Clean up
rm /tmp/fix_schema.sql

echo "✅ Database schema fixes applied successfully!" 