#!/bin/sh
set -e

echo "---------------------------------------------"
echo "🔧 Executing database schema updates..."
echo "---------------------------------------------"

# First check what columns exist before the fix
echo "Current users table columns BEFORE updates:"
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT column_name FROM information_schema.columns WHERE table_name = 'users' ORDER BY ordinal_position;"

# Apply the fixes with detailed output
echo "Applying column fixes (with detailed logging)..."
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -v ON_ERROR_STOP=0 -f /app/sql/fixes/all_columns_fix.sql
FIX_RESULT=$?

echo "---------------------------------------------"
echo "Checking updated users table columns AFTER fixes:"
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT column_name FROM information_schema.columns WHERE table_name = 'users' ORDER BY ordinal_position;"

# Explicitly check for required columns to make sure they exist
echo "Verifying required columns exist:"
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT 
    EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'password_hash') as has_password_hash,
    EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'display_name') as has_display_name,
    EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'profile_picture_url') as has_profile_picture_url,
    EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'location') as has_location,
    EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'latitude') as has_latitude,
    EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'longitude') as has_longitude;
"

if [ $FIX_RESULT -eq 0 ]; then
  echo "✅ Database schema updates completed successfully!"
else
  echo "⚠️ Database schema updates completed with warnings/errors. Check the logs above."
fi
echo "---------------------------------------------" 